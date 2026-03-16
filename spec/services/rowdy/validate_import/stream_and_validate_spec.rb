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

      let(:column_mapping) do
        {
          "name"     => "name",
          "sku"      => "sku",
          "price"    => "price",
          "stock"    => "stock",
          "category" => "category"
        }
      end

      def build_context(import:, xlsx:)
        LightService::Context.make(
          import: import,
          schema: ProductImportSchema,
          input_path: xlsx.path
        )
      end

      context "when all rows are valid" do
        it "sets valid_rows_count to the number of passing rows" do
          xlsx = create_test_xlsx(
            headers: %w[name sku price stock category],
            rows: [
              [ "T-Shirt", "SKU1", "19.99", "10", "clothing" ],
              [ "Jacket",  "SKU2", "49.99", "5",  "clothing" ]
            ]
          )
          import = create(:rowdy_import, :with_mapping, column_mapping: column_mapping)

          described_class.execute(build_context(import: import, xlsx: xlsx))

          import.reload
          expect(import.valid_rows_count).to eq(2)
          expect(import.invalid_rows_count).to eq(0)
        ensure
          xlsx&.close!
        end

        it "sets total_rows to the number of data rows" do
          xlsx = create_test_xlsx(
            headers: %w[name sku price stock category],
            rows: [
              [ "T-Shirt", "SKU1", "19.99", "10", "clothing" ],
              [ "Jacket",  "SKU2", "49.99", "5",  "clothing" ]
            ]
          )
          import = create(:rowdy_import, :with_mapping, column_mapping: column_mapping)

          described_class.execute(build_context(import: import, xlsx: xlsx))

          expect(import.reload.total_rows).to eq(2)
        ensure
          xlsx&.close!
        end

        it "sets progress to 100" do
          xlsx = create_test_xlsx(
            headers: %w[name sku price stock category],
            rows: [ [ "T-Shirt", "SKU1", "19.99", "10", "clothing" ] ]
          )
          import = create(:rowdy_import, :with_mapping, column_mapping: column_mapping)

          described_class.execute(build_context(import: import, xlsx: xlsx))

          expect(import.reload.progress).to eq(100)
        ensure
          xlsx&.close!
        end
      end

      context "when some rows are invalid" do
        it "counts invalid rows and persists all rows" do
          xlsx = create_test_xlsx(
            headers: %w[name sku price stock category],
            rows: [
              [ "T-Shirt", "SKU1", "19.99", "10", "clothing" ],
              [ nil,       "SKU2", "bad",   nil,  nil         ]
            ]
          )
          import = create(:rowdy_import, :with_mapping, column_mapping: column_mapping)

          described_class.execute(build_context(import: import, xlsx: xlsx))

          import.reload
          expect(import.valid_rows_count).to eq(1)
          expect(import.invalid_rows_count).to eq(1)
          expect(import.import_rows.count).to eq(2)
          expect(import.import_rows.errored.count).to eq(1)
        ensure
          xlsx&.close!
        end
      end

      context "row numbering" do
        it "records the correct row_number on the errored import_row (1-based, skipping header)" do
          xlsx = create_test_xlsx(
            headers: %w[name sku price stock category],
            rows: [
              [ "T-Shirt", "SKU1", "19.99", nil, nil ],
              [ nil,       "SKU2", "19.99", nil, nil ]
            ]
          )
          import = create(:rowdy_import, :with_mapping, column_mapping: column_mapping)

          described_class.execute(build_context(import: import, xlsx: xlsx))

          errored = import.import_rows.errored.first
          expect(errored.row_number).to eq(3)
        ensure
          xlsx&.close!
        end
      end
    end
  end
end
