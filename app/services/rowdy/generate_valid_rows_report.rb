module Rowdy
  class GenerateValidRowsReport
    BATCH_SIZE = 1_000

    def initialize(import)
      @import = import
    end

    def call
      tempfile = Tempfile.new([ "valid_rows_report", ".csv" ])
      tempfile.binmode

      CSV.open(tempfile.path, "wb") do |csv|
        csv << columns

        valid_rows.find_each(batch_size: BATCH_SIZE) do |row|
          csv << build_csv_row(row)
        end
      end

      tempfile
    rescue => e
      tempfile&.close
      tempfile&.unlink
      raise
    end

    private

    def columns
      @columns ||= @import.upload.detected_columns || []
    end

    def mapping
      @mapping ||= @import.column_mapping || {}
    end

    def valid_rows
      @import.import_rows.where(column_errors: nil)
    end

    def build_csv_row(row)
      columns.map { |col| row.row_data[mapping.fetch(col, col)] }
    end
  end
end
