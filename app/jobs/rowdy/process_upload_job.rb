module Rowdy
  class ProcessUploadJob < ApplicationJob
    queue_as :rowdy_processing

    def perform(upload_id)
      upload = Upload.find(upload_id)
      upload.update!(status: :processing, progress: 0)

      input_path = download_to_tempfile(upload.input_file)

      processor = Rowdy.configuration.processor
      output_path = processor.call(input_path, upload) do |progress|
        upload.update!(progress: progress)
      end

      upload.output_file.attach(
        io: File.open(output_path),
        filename: "processed_#{upload.filename}",
        content_type: upload.input_file.content_type
      )

      upload.update!(status: :completed, progress: 100)

    rescue => e
      upload.update!(
        status: :failed,
        error_message: e.message
      )
      raise
    ensure
      cleanup_tempfile(input_path) if input_path
    end

    private

    def download_to_tempfile(attachment)
      return nil unless attachment.attached?

      tempfile = Tempfile.new([attachment.filename.base, attachment.filename.extension_with_delimiter])
      tempfile.binmode
      attachment.download { |chunk| tempfile.write(chunk) }
      tempfile.rewind
      tempfile.path
    end

    def cleanup_tempfile(path)
      File.delete(path) if path && File.exist?(path)
    rescue => e
      Rails.logger.warn("Failed to cleanup tempfile #{path}: #{e.message}")
    end
  end
end
