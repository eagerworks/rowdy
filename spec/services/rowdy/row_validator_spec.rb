require "rails_helper"

module Rowdy
  RSpec.describe RowValidator do
    # ProductImportSchema columns:
    #   name:     string, required, max_length: 100
    #   sku:      string, required, unique
    #   price:    decimal, required, greater_than: 0
    #   stock:    integer, optional
    #   category: string, optional, inclusion: %w[electronics clothing food other]

    let(:valid_row) do
      { name: "T-Shirt", sku: "SKU1", price: BigDecimal("19.99"), stock: 100, category: "clothing" }
    end

    describe ".call" do
      context "when the row is valid" do
        it "returns no errors" do
          expect(described_class.call(valid_row, ProductImportSchema)).to be_empty
        end

        it "returns no errors for optional nil fields" do
          row = valid_row.merge(stock: nil, category: nil)
          expect(described_class.call(row, ProductImportSchema)).to be_empty
        end
      end

      context "when a required field is missing" do
        it "returns an error when the field is nil" do
          row = valid_row.merge(name: nil)
          errors = described_class.call(row, ProductImportSchema)
          expect(errors["name"]).to include("is required")
        end

        it "returns an error when the field is blank" do
          row = valid_row.merge(sku: "  ")
          errors = described_class.call(row, ProductImportSchema)
          expect(errors["sku"]).to include("is required")
        end
      end

      context "when a field fails a type constraint" do
        it "returns an error for a value with the wrong type" do
          row = valid_row.merge(price: "not-a-number")
          errors = described_class.call(row, ProductImportSchema)
          expect(errors["price"]).to include("must be a valid decimal")
        end
      end

      context "when a field fails a value constraint" do
        it "returns an error when string exceeds max_length" do
          row = valid_row.merge(name: "A" * 101)
          errors = described_class.call(row, ProductImportSchema)
          expect(errors["name"]).to include("must be at most 100 characters")
        end

        it "returns an error when value is outside inclusion list" do
          row = valid_row.merge(category: "unknown")
          errors = described_class.call(row, ProductImportSchema)
          expect(errors["category"]).to include("must be one of: electronics, clothing, food, other")
        end

        it "returns an error when numeric value is not greater than threshold" do
          row = valid_row.merge(price: BigDecimal("0"))
          errors = described_class.call(row, ProductImportSchema)
          expect(errors["price"]).to include("must be greater than 0")
        end
      end

      context "when a unique field is duplicated" do
        it "returns an error for the second occurrence" do
          tracker = UniqueTracker.new
          tracker.add?(:sku, "SKU1")
          row = valid_row.merge(sku: "SKU1")
          errors = described_class.call(row, ProductImportSchema, unique_tracker: tracker)
          expect(errors["sku"]).to include("must be unique")
        end

        it "returns no error for the first occurrence" do
          tracker = UniqueTracker.new
          errors = described_class.call(valid_row, ProductImportSchema, unique_tracker: tracker)
          expect(errors).to be_empty
        end
      end

      context "with a custom validation block" do
        it "includes the custom error message when validation fails" do
          schema = Class.new(Rowdy::Schema) do
            column :code, type: :string, required: true do
              validate { |val, errs| errs << "must start with X" unless val.to_s.start_with?("X") }
            end
          end
          errors = described_class.call({ code: "ABC" }, schema)
          expect(errors["code"]).to include("must start with X")
        end
      end

      context "when multiple constraints fail for the same column" do
        it "reports all errors for that column" do
          row = valid_row.merge(name: "A" * 101)
          errors = described_class.call(row, ProductImportSchema)
          expect(errors["name"]).not_to be_empty
        end
      end
    end
  end
end
