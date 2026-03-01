module Rowdy
  class InitiateUpload
    def self.call(filename:, file_size:, chunk_size: nil, schema_name: nil)
      chunk_size = (chunk_size || Rowdy.configuration.default_chunk_size).to_i
      total_chunks = (file_size.to_f / chunk_size).ceil

      upload = Upload.create!(
        filename: filename,
        size: file_size,
        status: :uploading,
        total_chunks: total_chunks,
        chunk_size: chunk_size,
        schema_name: schema_name.presence
      )

      dir = ChunkStorage.create_dir(upload.upload_token)
      upload.update!(chunks_dir: dir)

      upload
    end
  end
end
