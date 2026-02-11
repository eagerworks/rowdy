module Rowdy
  module ProcessUpload
    class ProcessFile
      extend LightService::Action

      expects :upload, :input_path
      promises :output_path

      executed do |ctx|
        processor = Rowdy.configuration.processor

        ctx.output_path = processor.call(ctx.input_path, ctx.upload) do |progress|
          ctx.upload.update!(progress: progress)
        end
      rescue => e
        ctx.fail!(e.message)
      end
    end
  end
end
