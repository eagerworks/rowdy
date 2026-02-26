require "rails_helper"

module Rowdy
  RSpec.describe InitiateUpload do
    after do
      Upload.where(status: :uploading).each { |u| ChunkStorage.cleanup(u.chunks_dir) }
    end

    describe ".call" do
      it "creates an upload in uploading status" do
        upload = described_class.call(filename: "data.xlsx", file_size: 10_000)
        expect(upload).to be_uploading
      end

      it "calculates total_chunks from file size and default chunk size" do
        chunk_size = Rowdy.configuration.default_chunk_size
        file_size  = chunk_size * 2 + 1

        upload = described_class.call(filename: "data.xlsx", file_size: file_size)
        expect(upload.total_chunks).to eq(3)
      end

      it "uses custom chunk_size when provided" do
        upload = described_class.call(filename: "data.xlsx", file_size: 1000, chunk_size: 300)
        expect(upload.total_chunks).to eq(4)
      end

      it "generates a unique upload_token for each upload" do
        a = described_class.call(filename: "a.xlsx", file_size: 1000)
        b = described_class.call(filename: "b.xlsx", file_size: 1000)
        expect(a.upload_token).not_to eq(b.upload_token)
      end

      it "creates the chunks directory on disk" do
        upload = described_class.call(filename: "data.xlsx", file_size: 1000)
        expect(Dir.exist?(upload.chunks_dir)).to be(true)
      end

      it "stores schema_name when provided" do
        upload = described_class.call(filename: "data.xlsx", file_size: 1000, schema_name: "ProductImportSchema")
        expect(upload.schema_name).to eq("ProductImportSchema")
      end

      it "leaves schema_name nil when not provided" do
        upload = described_class.call(filename: "data.xlsx", file_size: 1000)
        expect(upload.schema_name).to be_nil
      end
    end
  end
end
