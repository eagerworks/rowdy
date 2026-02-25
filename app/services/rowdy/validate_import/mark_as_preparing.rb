module Rowdy
  module ValidateImport
    class MarkAsPreparing
      extend LightService::Action

      expects :import

      executed do |ctx|
        ctx.import.import_errors.delete_all
        ctx.import.update!(status: :preparing, progress: 0, total_rows: 0,
                           valid_rows_count: 0, invalid_rows_count: 0)
      end
    end
  end
end
