require "rails_helper"

module Rowdy
  RSpec.describe ChunkStorage do
    let(:tmp_dir) { Dir.mktmpdir("rowdy_chunks_spec") }

    after { FileUtils.rm_rf(tmp_dir) }

    describe ".create_dir" do
      it "creates directory and returns path ending with the token" do
        Rowdy.configuration.chunks_storage_path = tmp_dir
        dir = described_class.create_dir("test_token_123")
        expect(Dir.exist?(dir)).to be(true)
        expect(dir).to end_with("test_token_123")
      ensure
        Rowdy.configuration.chunks_storage_path = nil
      end
    end

    describe ".chunk_path" do
      it "returns formatted path with zero-padded index" do
        path = described_class.chunk_path(tmp_dir, 5)
        expect(path).to eq(File.join(tmp_dir, "chunk_000005"))
      end
    end

    describe ".write_chunk" do
      it "writes data to the correct path" do
        path = described_class.write_chunk(tmp_dir, 0, "hello chunk")
        expect(File.exist?(path)).to be(true)
        expect(File.read(path)).to eq("hello chunk")
      end
    end

    describe ".assemble" do
      it "concatenates chunks in order" do
        described_class.write_chunk(tmp_dir, 0, "chunk0")
        described_class.write_chunk(tmp_dir, 1, "chunk1")
        described_class.write_chunk(tmp_dir, 2, "chunk2")

        output = Tempfile.new("assembled")
        described_class.assemble(tmp_dir, 3, output.path)
        expect(File.read(output.path)).to eq("chunk0chunk1chunk2")
      ensure
        output&.unlink
      end

      it "raises if a chunk file is missing" do
        described_class.write_chunk(tmp_dir, 0, "chunk0")
        output = Tempfile.new("assembled")
        expect { described_class.assemble(tmp_dir, 2, output.path) }.to raise_error(RuntimeError)
      ensure
        output&.unlink
      end
    end

    describe ".cleanup" do
      it "removes the directory and its contents" do
        dir = File.join(tmp_dir, "to_delete")
        FileUtils.mkdir_p(dir)
        File.write(File.join(dir, "chunk_000000"), "data")

        described_class.cleanup(dir)
        expect(Dir.exist?(dir)).to be(false)
      end

      it "is a no-op for nil" do
        expect { described_class.cleanup(nil) }.not_to raise_error
      end

      it "is a no-op for non-existent directory" do
        expect { described_class.cleanup("/non/existent/path") }.not_to raise_error
      end
    end
  end
end
