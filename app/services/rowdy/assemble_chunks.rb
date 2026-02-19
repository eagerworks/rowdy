module Rowdy
  class AssembleChunks
    def self.call(upload)
      tempfile = Tempfile.new([ upload.filename, File.extname(upload.filename) ])
      tempfile.binmode

      ChunkStorage.assemble(upload.chunks_dir, upload.total_chunks, tempfile.path)

      upload.input_file.attach(
        io: File.open(tempfile.path),
        filename: upload.filename,
        content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      )

      upload.update!(status: :pending)

      ChunkStorage.cleanup(upload.chunks_dir)

      ProcessUploadJob.perform_now(upload.id)
    ensure
      tempfile&.unlink
    end
  end
end
