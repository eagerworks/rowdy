require "rails_helper"

module Rowdy
  module ValidateImport
    RSpec.describe StreamAndValidate do
      # ProductImportSchema columns:
      #   name:     string, required, max_length: 100
      #   sku:      string, required, unique
      #   price:    decimal, required, greater_than: 0
      #   stock:    integer, optional
      #   category: string, optional, inclusion: %w[electronics clothing food other]

      COLUMN_MAPPING = {
        "name"     => "name",
        "sku"      => "sku",
        "price"    => "price",
        "stock"    => "stock",
        "category" => "category"
      }.freeze

      def build_context(import:, xlsx:)
        import.upload.input_file.attach(
          io: File.open(xlsx.path),
          filename: "test.xlsx",
          content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        )
        LightService::Context.make(
          import: import,
          schema: ProductImportSchema,
          input_path: xlsx.path
        )
      end

      it "counts valid rows correctly" do
        xlsx = create_test_xlsx(
          headers: %w[name sku price stock category],
          rows: [
            [ "T-Shirt", "SKU1", "19.99", "10", "clothing" ],
            [ "Jacket",  "SKU2", "49.99", "5",  "clothing" ]
          ]
        )
        import = create(:rowdy_import, :with_mapping, column_mapping: COLUMN_MAPPING)

        described_class.execute(build_context(import: import, xlsx: xlsx))

        import.reload
        expect(import.valid_rows_count).to eq(2)
        expect(import.invalid_rows_count).to eq(0)
      ensure
        xlsx&.close!
      end

      it "counts invalid rows and creates ImportErrors" do
        xlsx = create_test_xlsx(
          headers: %w[name sku price stock category],
          rows: [
            [ "T-Shirt", "SKU1", "19.99", "10", "clothing" ],
            [ nil,       "SKU2", "bad",   nil,  nil         ]
          ]
        )
        import = create(:rowdy_import, :with_mapping, column_mapping: COLUMN_MAPPING)

        described_class.execute(build_context(import: import, xlsx: xlsx))

        import.reload
        expect(import.valid_rows_count).to eq(1)
        expect(import.invalid_rows_count).to eq(1)
        expect(import.import_errors.count).to eq(1)
      ensure
        xlsx&.close!
      end

      it "sets import total_rows after processing" do
        xlsx = create_test_xlsx(
          headers: %w[name sku price stock category],
          rows: [
            [ "T-Shirt", "SKU1", "19.99", "10", "clothing" ],
            [ "Jacket",  "SKU2", "49.99", "5",  "clothing" ]
          ]
        )
        import = create(:rowdy_import, :with_mapping, column_mapping: COLUMN_MAPPING)

        described_class.execute(build_context(import: import, xlsx: xlsx))

        expect(import.reload.total_rows).to eq(2)
      ensure
        xlsx&.close!
      end

      it "sets progress to 100 after processing" do
        xlsx = create_test_xlsx(
          headers: %w[name sku price stock category],
          rows: [ [ "T-Shirt", "SKU1", "19.99", "10", "clothing" ] ]
        )
        import = create(:rowdy_import, :with_mapping, column_mapping: COLUMN_MAPPING)

        described_class.execute(build_context(import: import, xlsx: xlsx))

        expect(import.reload.progress).to eq(100)
      ensure
        xlsx&.close!
      end

      it "records the correct row_number on import_error" do
        xlsx = create_test_xlsx(
          headers: %w[name sku price stock category],
          rows: [
            [ "T-Shirt", "SKU1", "19.99", nil, nil ],
            [ nil,       "SKU2", "19.99", nil, nil ]
          ]
        )
        import = create(:rowdy_import, :with_mapping, column_mapping: COLUMN_MAPPING)

        described_class.execute(build_context(import: import, xlsx: xlsx))

        error = import.import_errors.first
        expect(error.row_number).to eq(3)
      ensure
        xlsx&.close!
      end
    end
  end
end
