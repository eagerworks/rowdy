module XlsxHelper
  def create_test_xlsx(headers:, rows: [])
    require "caxlsx"
    tempfile = Tempfile.new([ "test", ".xlsx" ])
    package = Axlsx::Package.new
    package.workbook.add_worksheet do |sheet|
      sheet.add_row headers
      rows.each { |row| sheet.add_row row }
    end
    package.serialize(tempfile.path)
    tempfile
  end
end
