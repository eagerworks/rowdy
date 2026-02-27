require "rails_helper"

module Rowdy
  RSpec.describe ReceiveChunk do
    let(:upload) { InitiateUpload.call(filename: "data.xlsx", file_size: 300, chunk_size: 100) }

    after { ChunkStorage.cleanup(upload.chunks_dir) }

    describe ".call" do
      context "when upload is uploading" do
        it "writes the chunk and returns a result struct" do
          result = described_class.call(upload: upload, chunk_index: 0, chunk_data: "A" * 100)
          expect(result.chunk_index).to eq(0)
          expect(result.received_chunks).to include(0)
          expect(result.upload_progress_percent).to be_a(Numeric)
        end

        it "adds the chunk index to received_chunks on the upload" do
          described_class.call(upload: upload, chunk_index: 1, chunk_data: "B" * 100)
          expect(upload.reload.received_chunks).to include(1)
        end

        it "is idempotent when receiving the same chunk twice" do
          described_class.call(upload: upload, chunk_index: 0, chunk_data: "A" * 100)
          result = described_class.call(upload: upload, chunk_index: 0, chunk_data: "A" * 100)
          expect(result.chunk_index).to eq(0)
        end

        it "increases upload_progress_percent as more chunks are received" do
          r0 = described_class.call(upload: upload, chunk_index: 0, chunk_data: "A" * 100)
          r1 = described_class.call(upload: upload, chunk_index: 1, chunk_data: "B" * 100)
          expect(r1.upload_progress_percent).to be >= r0.upload_progress_percent
        end
      end

      context "when upload is not in uploading status" do
        it "raises UploadNotUploadingError" do
          other = InitiateUpload.call(filename: "data.xlsx", file_size: 300, chunk_size: 100)
          other.update_column(:status, Upload.statuses[:pending])

          expect {
            described_class.call(upload: other, chunk_index: 0, chunk_data: "data")
          }.to raise_error(ReceiveChunk::UploadNotUploadingError)
        ensure
          ChunkStorage.cleanup(other&.chunks_dir)
        end
      end

      context "with an invalid chunk index" do
        it "raises InvalidChunkIndexError for a negative index" do
          expect {
            described_class.call(upload: upload, chunk_index: -1, chunk_data: "data")
          }.to raise_error(ReceiveChunk::InvalidChunkIndexError)
        end

        it "raises InvalidChunkIndexError for an index >= total_chunks" do
          expect {
            described_class.call(upload: upload, chunk_index: 3, chunk_data: "data")
          }.to raise_error(ReceiveChunk::InvalidChunkIndexError)
        end
      end
    end
  end
end
