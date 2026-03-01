module Rowdy
  module ValidateImport
    class MarkAsPreparing
      def self.call(import_id)
        import = Rowdy::Import.find(import_id)

        import.import_errors.delete_all
        import.update!(status: :preparing, progress: 0, total_rows: 0,
                          valid_rows_count: 0, invalid_rows_count: 0)
      end
    end
  end
end
