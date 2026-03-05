# frozen_string_literal: true

require "rails_helper"

module Rowdy
  module ColumnValidators
    RSpec.describe TypeValidator do
      describe ".execute" do
        let(:errors) { [] }

        context "with coercible values" do
          it "returns coerced value and adds no error for string type" do
            col = ColumnDefinition.new(name: :title, type: :string)
            result = described_class.execute(value: 123, column: col, errors: errors)
            expect(errors).to be_empty
            expect(result.coerced_value).to eq("123")
          end

          it "returns coerced value for integer type" do
            col = ColumnDefinition.new(name: :count, type: :integer)
            result = described_class.execute(value: "42", column: col, errors: errors)
            expect(errors).to be_empty
            expect(result.coerced_value).to eq(42)
          end

          it "returns coerced value for decimal type" do
            col = ColumnDefinition.new(name: :price, type: :decimal)
            result = described_class.execute(value: "19.99", column: col, errors: errors)
            expect(errors).to be_empty
            expect(result.coerced_value).to eq(BigDecimal("19.99"))
          end

          it "returns nil for nil and adds no error (blank is skipped by caller)" do
            col = ColumnDefinition.new(name: :optional, type: :string)
            result = described_class.execute(value: nil, column: col, errors: errors)
            expect(errors).to be_empty
            expect(result.coerced_value).to be_nil
          end
        end

        context "with non-coercible values" do
          it "adds error and returns nil for invalid decimal" do
            col = ColumnDefinition.new(name: :price, type: :decimal)
            result = described_class.execute(value: "not-a-number", column: col, errors: errors)
            expect(errors).to eq([ "Must be a valid decimal" ])
            expect(result.coerced_value).to be_nil
          end

          it "adds error and returns nil for invalid integer" do
            col = ColumnDefinition.new(name: :count, type: :integer)
            result = described_class.execute(value: "abc", column: col, errors: errors)
            expect(errors).to eq([ "Must be a valid integer" ])
            expect(result.coerced_value).to be_nil
          end

          it "uses column type in error message" do
            col = ColumnDefinition.new(name: :birthday, type: :date)
            described_class.execute(value: "not-a-date", column: col, errors: errors)
            expect(errors).to eq([ "Must be a valid date" ])
          end
        end
      end
    end
  end
end
