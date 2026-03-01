module Rowdy
  module ProcessUpload
    class DetectAndStoreColumns
      extend LightService::Action

      expects :upload, :input_path

      executed do |ctx|
        result = DetectColumns.call(ctx.input_path)
        ctx.upload.update!(
          detected_columns: result[:headers],
          sample_rows: result[:sample_rows],
          sheet_dimension: result[:sheet_dimension]
        )
      rescue => e
        Rails.logger.error("DetectAndStoreColumns failed for Upload ID #{ctx.upload.id}: #{e.message}")
      end
    end
  end
end
