# frozen_string_literal: true

require "rails_helper"

module Rowdy
  module ColumnValidators
    RSpec.describe TypeValidator do
      describe ".call" do
        let(:errors) { [] }

        context "with coercible values" do
          it "returns coerced value and adds no error for string type" do
            col = ColumnDefinition.new(name: :title, type: :string)
            result = described_class.call(123, col, errors)
            expect(errors).to be_empty
            expect(result).to eq("123")
          end

          it "returns coerced value for integer type" do
            col = ColumnDefinition.new(name: :count, type: :integer)
            result = described_class.call("42", col, errors)
            expect(errors).to be_empty
            expect(result).to eq(42)
          end

          it "returns coerced value for decimal type" do
            col = ColumnDefinition.new(name: :price, type: :decimal)
            result = described_class.call("19.99", col, errors)
            expect(errors).to be_empty
            expect(result).to eq(BigDecimal("19.99"))
          end

          it "returns nil for nil and adds no error (blank is skipped by caller)" do
            col = ColumnDefinition.new(name: :optional, type: :string)
            result = described_class.call(nil, col, errors)
            expect(errors).to be_empty
            expect(result).to be_nil
          end
        end

        context "with non-coercible values" do
          it "adds error and returns nil for invalid decimal" do
            col = ColumnDefinition.new(name: :price, type: :decimal)
            result = described_class.call("not-a-number", col, errors)
            expect(errors).to eq([ "must be a valid decimal" ])
            expect(result).to be_nil
          end

          it "adds error and returns nil for invalid integer" do
            col = ColumnDefinition.new(name: :count, type: :integer)
            result = described_class.call("abc", col, errors)
            expect(errors).to eq([ "must be a valid integer" ])
            expect(result).to be_nil
          end

          it "uses column type in error message" do
            col = ColumnDefinition.new(name: :birthday, type: :date)
            described_class.call("not-a-date", col, errors)
            expect(errors).to eq([ "must be a valid date" ])
          end
        end
      end
    end
  end
end
