module Rowdy
  class ReceiveChunk
    class UploadNotUploadingError < StandardError; end
    class InvalidChunkIndexError < StandardError; end

    Result = Struct.new(:chunk_index, :received_chunks, :upload_progress_percent, keyword_init: true)

    def self.call(upload:, chunk_index:, chunk_data:)
      raise UploadNotUploadingError, "Upload is not in uploading state" unless upload.uploading?
      raise InvalidChunkIndexError, "Invalid chunk index" unless chunk_index >= 0 && chunk_index < upload.total_chunks

      if upload.received_chunks.include?(chunk_index)
        return Result.new(
          chunk_index: chunk_index,
          received_chunks: upload.received_chunks,
          upload_progress_percent: upload.upload_progress_percent
        )
      end

      ChunkStorage.write_chunk(upload.chunks_dir, chunk_index, chunk_data)

      upload.with_lock do
        upload.reload
        upload.received_chunks << chunk_index
        upload.save!
      end

      Result.new(
        chunk_index: chunk_index,
        received_chunks: upload.received_chunks,
        upload_progress_percent: upload.upload_progress_percent
      )
    end
  end
end
