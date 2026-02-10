module Rowdy
  module ProcessUpload
    class MarkAsProcessing
      extend LightService::Action

      expects :upload

      executed do |ctx|
        ctx.upload.update!(status: :processing, progress: 0)
      end
    end
  end
end
