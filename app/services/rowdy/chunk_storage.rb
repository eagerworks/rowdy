module Rowdy
  class ChunkStorage
    def self.base_path
      Rowdy.configuration.chunks_storage_path || Rails.root.join("tmp", "rowdy_chunks")
    end

    def self.create_dir(upload_token)
      dir = File.join(base_path.to_s, upload_token)
      FileUtils.mkdir_p(dir)
      dir
    end

    def self.write_chunk(chunks_dir, index, data)
      path = chunk_path(chunks_dir, index)
      File.open(path, "wb") { |f| f.write(data) }
      path
    end

    def self.chunk_path(chunks_dir, index)
      File.join(chunks_dir, "chunk_#{index.to_s.rjust(6, '0')}")
    end

    def self.assemble(chunks_dir, total_chunks, output_path)
      File.open(output_path, "wb") do |out|
        total_chunks.times do |i|
          path = chunk_path(chunks_dir, i)
          raise "Missing chunk file: #{path}" unless File.exist?(path)

          File.open(path, "rb") { |f| IO.copy_stream(f, out) }
        end
      end
      output_path
    end

    def self.cleanup(chunks_dir)
      FileUtils.rm_rf(chunks_dir) if chunks_dir && Dir.exist?(chunks_dir)
    end
  end
end
