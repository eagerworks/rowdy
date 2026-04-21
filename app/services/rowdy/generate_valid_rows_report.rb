require "csv"

module Rowdy
  class GenerateValidRowsReport
    def initialize(import)
      @import = import
    end

    def call
      original_columns = @import.upload.detected_columns || []
      mapping = @import.column_mapping || {}

      tempfile = Tempfile.new([ "valid_rows_report", ".csv" ])
      tempfile.binmode

      CSV.open(tempfile.path, "wb") do |csv|
        csv << original_columns

        @import.import_rows.where(column_errors: nil).find_each(batch_size: 1000) do |row|
          csv << original_columns.map do |col|
            if mapping.key?(col)
              row.row_data[mapping[col]]
            else
              row.row_data[col]
            end
          end
        end
      end

      tempfile
    end
  end
end
