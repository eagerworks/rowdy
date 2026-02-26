require "rails_helper"

module Rowdy
  RSpec.describe DetectColumns do
    describe ".call" do
      it "extracts headers from the first row" do
        xlsx = create_test_xlsx(headers: %w[name sku price], rows: [ [ "T-Shirt", "SKU1", "19.99" ] ])
        result = described_class.call(xlsx.path)
        expect(result[:headers]).to eq(%w[name sku price])
      ensure
        xlsx&.close!
      end

      it "normalizes empty header to Column N" do
        xlsx = create_test_xlsx(headers: [ "name", "", "price" ], rows: [])
        result = described_class.call(xlsx.path)
        expect(result[:headers]).to eq([ "name", "Column 2", "price" ])
      ensure
        xlsx&.close!
      end

      it "renames duplicate headers with suffix" do
        xlsx = create_test_xlsx(headers: [ "name", "name", "name" ], rows: [])
        result = described_class.call(xlsx.path)
        expect(result[:headers]).to eq([ "name", "name_2", "name_3" ])
      ensure
        xlsx&.close!
      end

      it "returns up to 3 sample rows" do
        rows = [
          [ "A", "1", "10.0" ],
          [ "B", "2", "20.0" ],
          [ "C", "3", "30.0" ],
          [ "D", "4", "40.0" ]
        ]
        xlsx = create_test_xlsx(headers: %w[name sku price], rows: rows)
        result = described_class.call(xlsx.path)
        expect(result[:sample_rows].size).to eq(3)
      ensure
        xlsx&.close!
      end

      it "returns fewer sample rows when file has fewer data rows" do
        xlsx = create_test_xlsx(headers: %w[name sku price], rows: [ [ "A", "1", "9.99" ] ])
        result = described_class.call(xlsx.path)
        expect(result[:sample_rows].size).to eq(1)
      ensure
        xlsx&.close!
      end

      it "returns empty sample_rows for header-only file" do
        xlsx = create_test_xlsx(headers: %w[name sku price], rows: [])
        result = described_class.call(xlsx.path)
        expect(result[:sample_rows]).to be_empty
      ensure
        xlsx&.close!
      end
    end
  end
end
