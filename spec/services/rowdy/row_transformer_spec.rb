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
      context "type coercion" do
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
      end

      context "default values" do
        let(:schema_with_default) do
          Class.new(Rowdy::Schema) do
            column :status, type: :string, required: false, default: "active"
          end
        end

        it "applies default value when field is nil" do
          result = described_class.call({ status: nil }, schema_with_default)
          expect(result[:status]).to eq("active")
        end

        it "does not overwrite a present value with the default" do
          result = described_class.call({ status: "inactive" }, schema_with_default)
          expect(result[:status]).to eq("inactive")
        end
      end

      context "custom transformation" do
        it "applies the transform block to the field value" do
          schema = Class.new(Rowdy::Schema) do
            column :name, type: :string, required: false do
              transform { |v| v&.upcase }
            end
          end
          result = described_class.call({ name: "t-shirt" }, schema)
          expect(result[:name]).to eq("T-SHIRT")
        end
      end

      context "when coercion fails" do
        it "falls back to the raw value" do
          row = { name: "T-Shirt", sku: "SKU1", price: "not-a-number", stock: nil, category: nil }
          result = described_class.call(row, ProductImportSchema)
          expect(result[:price]).to eq("not-a-number")
        end
      end
    end
  end
end
