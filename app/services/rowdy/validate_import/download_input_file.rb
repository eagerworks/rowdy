module Rowdy
  module ValidateImport
    class DownloadInputFile
      extend LightService::Action

      expects :upload
      promises :input_path

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

        ctx.input_path = tempfile.path
      end
    end
  end
end
