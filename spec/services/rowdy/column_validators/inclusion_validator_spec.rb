# frozen_string_literal: true

require "rails_helper"

module Rowdy
  module ColumnValidators
    RSpec.describe InclusionValidator do
      describe "#call" do
        let(:errors) { [] }
        let(:allowed) { %w[electronics clothing food other] }
        let(:column) { ColumnDefinition.new(name: :category, type: :string, inclusion: allowed) }

        it "adds no error when value is in the inclusion list" do
          validator = described_class.new(value: "clothing", column: column, errors: errors)
          validator.call
          expect(errors).to be_empty
        end

        it "compares using string representation" do
          validator = described_class.new(value: :electronics, column: column, errors: errors)
          validator.call
          expect(errors).to be_empty
        end

        it "adds error when value is not in the inclusion list" do
          validator = described_class.new(value: "unknown", column: column, errors: errors)
          validator.call
          expect(errors).to eq([ "must be one of: electronics, clothing, food, other" ])
        end

        it "adds error for nil (to_s => '')" do
          validator = described_class.new(value: nil, column: column, errors: errors)
          validator.call
          expect(errors).to eq([ "must be one of: electronics, clothing, food, other" ])
        end

        it "formats inclusion list in error message" do
          col = ColumnDefinition.new(name: :status, type: :string, inclusion: %w[active inactive])
          validator = described_class.new(value: "pending", column: col, errors: errors)
          validator.call
          expect(errors).to eq([ "must be one of: active, inactive" ])
        end
      end
    end
  end
end
