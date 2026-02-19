require "creek"

module Rowdy
  class DetectColumns
    SAMPLE_ROWS_COUNT = 3

    def self.call(file_path)
      book = Creek::Book.new(file_path)
      sheet = book.sheets.first

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

      { headers: headers, sample_rows: sample_rows }
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

    private_class_method :normalize_headers
  end
end
