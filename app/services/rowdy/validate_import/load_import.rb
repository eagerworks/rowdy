module Rowdy
  module ValidateImport
    class LoadImport
      extend LightService::Action

      expects :import_id
      promises :import, :upload, :schema

      executed do |ctx|
        ctx.import = Import.find(ctx.import_id)
        ctx.upload = ctx.import.upload
        ctx.schema = ctx.import.schema
      rescue ActiveRecord::RecordNotFound => e
        ctx.fail!(e.message)
      end
    end
  end
end
