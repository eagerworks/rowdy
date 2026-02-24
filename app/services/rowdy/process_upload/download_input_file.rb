module Rowdy
  module ProcessUpload
    class DownloadInputFile
      extend LightService::Action

      expects :upload
      promises :input_path, :tempfile

      executed do |ctx|
        attachment = ctx.upload.input_file
        ctx.fail!("No input file attached") unless attachment.attached?

        tempfile = Tempfile.new([
          attachment.filename.base,
          attachment.filename.extension_with_delimiter
        ])
        tempfile.binmode

        attachment.download { |chunk| tempfile.write(chunk) }
        tempfile.rewind

        ctx.tempfile = tempfile
        ctx.input_path = tempfile.path
      end
    end
  end
end
