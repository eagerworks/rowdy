require "rails_helper"

module Rowdy
  RSpec.describe AssembleChunks do
    let(:upload) do
      InitiateUpload.call(filename: "data.xlsx", file_size: 30, chunk_size: 10)
    end

    before do
      ChunkStorage.write_chunk(upload.chunks_dir, 0, "AAAAAAAAAA")
      ChunkStorage.write_chunk(upload.chunks_dir, 1, "BBBBBBBBBB")
      ChunkStorage.write_chunk(upload.chunks_dir, 2, "CCCCCCCCCC")
      allow(ProcessUploadJob).to receive(:perform_now)
    end

    describe ".call" do
      it "attaches the assembled file to upload.input_file" do
        described_class.call(upload)
        expect(upload.reload.input_file).to be_attached
      end

      it "sets upload status to pending before the job runs" do
        status_at_call_time = nil
        allow(ProcessUploadJob).to receive(:perform_now) do |id|
          status_at_call_time = Rowdy::Upload.find(id).status
        end

        described_class.call(upload)
        expect(status_at_call_time).to eq("pending")
      end

      it "cleans up the chunks directory after assembly" do
        chunks_dir = upload.chunks_dir
        described_class.call(upload)
        expect(Dir.exist?(chunks_dir)).to be(false)
      end

      it "calls ProcessUploadJob with the upload id" do
        described_class.call(upload)
        expect(ProcessUploadJob).to have_received(:perform_now).with(upload.id)
      end
    end
  end
end
