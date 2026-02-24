require "csv"

module Rowdy
  module ValidateImport
    class GenerateErrorReport
      extend LightService::Action

      expects :import

      executed do |ctx|
        import = ctx.import

        next ctx if import.invalid_rows_count.zero?

        tempfile = Tempfile.new(["error_report", ".csv"])
        tempfile.binmode

        CSV.open(tempfile.path, "wb") do |csv|
          csv << ["Row", "Column", "Error", "Value"]

          import.import_errors.find_each(batch_size: 1000) do |error|
            row_data = error.row_data || {}
            (error.column_errors || {}).each do |column, messages|
              messages.each do |message|
                csv << [error.row_number, column, message, row_data[column]]
              end
            end
          end
        end

        import.error_report.attach(
          io: File.open(tempfile.path),
          filename: "error_report_#{import.id}.csv",
          content_type: "text/csv"
        )
      ensure
        tempfile&.close
        tempfile&.unlink
      end
    end
  end
end
