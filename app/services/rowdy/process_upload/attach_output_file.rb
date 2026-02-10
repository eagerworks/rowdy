module Rowdy
  module ProcessUpload
    class AttachOutputFile
      extend LightService::Action

      expects :upload, :output_path

      executed do |ctx|
        ctx.upload.output_file.attach(
          io: File.open(ctx.output_path),
          filename: "processed_#{ctx.upload.filename}",
          content_type: ctx.upload.input_file.content_type
        )
      end
    end
  end
end
