module Rowdy
  module ProcessUpload
    class LoadUpload
      extend LightService::Action

      expects :upload_id
      promises :upload

      executed do |ctx|
        ctx.upload = Upload.find(ctx.upload_id)
      rescue ActiveRecord::RecordNotFound => e
        ctx.fail!(e.message)
      end
    end
  end
end
