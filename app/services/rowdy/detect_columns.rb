require "creek"

module Rowdy
  class DetectColumns
    SAMPLE_ROWS_COUNT = 3

    def self.call(file_path)
      book = Creek::Book.new(file_path)
      sheet = book.sheets.first
      sheet_dimension = sheet_bytesize(file_path)

      headers = []
      sample_rows = []

      sheet.rows.each_with_index do |row, index|
        values = row.values

        if index.zero?
          headers = normalize_headers(values)
        else
          sample_rows << values
          break if sample_rows.size >= SAMPLE_ROWS_COUNT
        end
      end

      { headers: headers, sample_rows: sample_rows, sheet_dimension: sheet_dimension }
    ensure
      book&.close
    end

    def self.normalize_headers(values)
      seen = Hash.new(0)

      values.map do |val|
        name = val.to_s.strip
        name = "Column #{seen.size + 1}" if name.empty?

        seen[name] += 1
        seen[name] > 1 ? "#{name}_#{seen[name]}" : name
      end
    end

    def self.sheet_bytesize(xlsx_path)
      Zip::File.open(xlsx_path) do |zip|
        entry = zip.glob("xl/worksheets/sheet1.xml").first
        return entry.size if entry
      end
    end

    private_class_method :normalize_headers, :sheet_bytesize
  end
end
