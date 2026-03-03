# frozen_string_literal: true

require "rails_helper"

module Rowdy
  module ColumnValidators
    RSpec.describe GreaterThanValidator do
      describe "#call" do
        let(:errors) { [] }
        let(:column) { ColumnDefinition.new(name: :price, type: :decimal, greater_than: 0) }

        it "adds no error when value is greater than threshold" do
          validator = described_class.new(value: BigDecimal("19.99"), column: column, errors: errors)
          validator.call
          expect(errors).to be_empty
        end

        it "adds error when value equals threshold" do
          validator = described_class.new(value: 0, column: column, errors: errors)
          validator.call
          expect(errors).to eq([ "must be greater than 0" ])
        end

        it "adds error when value is less than threshold" do
          validator = described_class.new(value: BigDecimal("-1.5"), column: column, errors: errors)
          validator.call
          expect(errors).to eq([ "must be greater than 0" ])
        end

        it "adds no error when value is not numeric" do
          validator = described_class.new(value: "hello", column: column, errors: errors)
          validator.call
          expect(errors).to be_empty
        end

        it "includes threshold in error message for custom threshold" do
          col = ColumnDefinition.new(name: :age, type: :integer, greater_than: 17)
          validator = described_class.new(value: 15, column: col, errors: errors)
          validator.call
          expect(errors).to eq([ "must be greater than 17" ])
        end
      end
    end
  end
end
