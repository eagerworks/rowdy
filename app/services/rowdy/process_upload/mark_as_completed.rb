module Rowdy
  module ProcessUpload
    class MarkAsCompleted
      extend LightService::Action

      expects :upload

      executed do |ctx|
        ctx.upload.update!(status: :completed, progress: 100)
      end
    end
  end
end
