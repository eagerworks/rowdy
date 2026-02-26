require "rails_helper"

module Rowdy
  RSpec.describe RowTransformer do
    # ProductImportSchema columns:
    #   name:     string, required, max_length: 100
    #   sku:      string, required, unique
    #   price:    decimal, required, greater_than: 0
    #   stock:    integer, optional
    #   category: string, optional, inclusion: %w[electronics clothing food other]

    describe ".call" do
      it "coerces price string to BigDecimal" do
        row = { name: "T-Shirt", sku: "SKU1", price: "19.99", stock: "100", category: "clothing" }
        result = described_class.call(row, ProductImportSchema)
        expect(result[:price]).to be_a(BigDecimal)
        expect(result[:price]).to eq(BigDecimal("19.99"))
      end

      it "coerces stock string to integer" do
        row = { name: "T-Shirt", sku: "SKU1", price: "19.99", stock: "50", category: "clothing" }
        result = described_class.call(row, ProductImportSchema)
        expect(result[:stock]).to eq(50)
      end

      it "keeps nil for nil optional fields" do
        row = { name: "T-Shirt", sku: "SKU1", price: "19.99", stock: nil, category: nil }
        result = described_class.call(row, ProductImportSchema)
        expect(result[:stock]).to be_nil
        expect(result[:category]).to be_nil
      end

      it "applies default value when field is nil" do
        schema = Class.new(Rowdy::Schema) do
          column :status, type: :string, required: false, default: "active"
        end
        result = described_class.call({ status: nil }, schema)
        expect(result[:status]).to eq("active")
      end

      it "does not overwrite present value with default" do
        schema = Class.new(Rowdy::Schema) do
          column :status, type: :string, required: false, default: "active"
        end
        result = described_class.call({ status: "inactive" }, schema)
        expect(result[:status]).to eq("inactive")
      end

      it "applies custom transformation" do
        schema = Class.new(Rowdy::Schema) do
          column :name, type: :string, required: false do
            transform { |v| v&.upcase }
          end
        end
        result = described_class.call({ name: "t-shirt" }, schema)
        expect(result[:name]).to eq("T-SHIRT")
      end

      it "returns raw value when coercion returns nil" do
        row = { name: "T-Shirt", sku: "SKU1", price: "not-a-number", stock: nil, category: nil }
        result = described_class.call(row, ProductImportSchema)
        expect(result[:price]).to eq("not-a-number")
      end
    end
  end
end
