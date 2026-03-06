# frozen_string_literal: true

require "rails_helper"

module Rowdy
  RSpec.describe RowValidator do
    # ProductImportSchema columns:
    #   name:     string, required, max_length: 100
    #   sku:      string, required, unique
    #   price:    decimal, required, greater_than: 0
    #   stock:    integer, optional
    #   category: string, optional, inclusion: %w[electronics clothing food other]

    let(:valid_row) { build(:rowdy_validator_row).to_h }
    let(:product_import_schema) { ProductImportSchema }

    describe ".call" do
      context "when the row is valid" do
        it "returns no errors" do
          expect(described_class.call(valid_row, product_import_schema)).to be_empty
        end

        it "returns no errors for optional nil fields" do
          row = build(:rowdy_validator_row, :with_optional_nils).to_h
          expect(described_class.call(row, product_import_schema)).to be_empty
        end
      end

      context "when a required field is missing" do
        it "returns an error when the field is nil" do
          row = build(:rowdy_validator_row, :with_blank_name).to_h
          errors = described_class.call(row, product_import_schema)
          expect(errors["name"]).to include("Is required")
        end

        it "returns an error when the field is blank" do
          row = build(:rowdy_validator_row, :with_blank_sku).to_h
          errors = described_class.call(row, product_import_schema)
          expect(errors["sku"]).to include("Is required")
        end
      end

      context "when a field fails a type constraint" do
        it "returns an error for a value with the wrong type" do
          row = build(:rowdy_validator_row, :invalid_price_type).to_h
          errors = described_class.call(row, product_import_schema)
          expect(errors["price"]).to include("Must be a valid decimal")
        end
      end

      context "when a field fails a value constraint" do
        it "returns an error when string exceeds max_length" do
          row = build(:rowdy_validator_row, :name_exceeds_max_length).to_h
          errors = described_class.call(row, product_import_schema)
          expect(errors["name"]).to include("Must be at most 100 characters")
        end

        it "returns an error when value is outside inclusion list" do
          row = build(:rowdy_validator_row, :category_outside_inclusion).to_h
          errors = described_class.call(row, product_import_schema)
          expect(errors["category"]).to include("Must be one of: electronics, clothing, food, other")
        end

        it "returns an error when numeric value is not greater than threshold" do
          row = build(:rowdy_validator_row, :price_not_greater_than_zero).to_h
          errors = described_class.call(row, product_import_schema)
          expect(errors["price"]).to include("Must be greater than 0")
        end
      end

      context "when a unique field is duplicated" do
        it "returns an error for the second occurrence" do
          tracker = UniqueTracker.new
          tracker.add?(:sku, "SKU1")
          row = build(:rowdy_validator_row, :duplicate_sku).to_h
          errors = described_class.call(row, product_import_schema, unique_tracker: tracker)
          expect(errors["sku"]).to include("Must be unique")
        end

        it "returns no error for the first occurrence" do
          tracker = UniqueTracker.new
          errors = described_class.call(valid_row, product_import_schema, unique_tracker: tracker)
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
          schema = Class.new(Rowdy::Schema) do
            column :code, type: :string, required: true, max_length: 5 do
              validate { |val, errs| errs << "must start with X" unless val.to_s.start_with?("X") }
            end
          end
          row = { code: "ABCDEF" } # too long and does not start with X
          errors = described_class.call(row, schema)
          expect(errors["code"]).to include("Must be at most 5 characters", "must start with X")
        end
      end
    end
  end
end
