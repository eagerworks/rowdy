# frozen_string_literal: true

require "rails_helper"

module Rowdy
  module ColumnValidators
    RSpec.describe MaxLengthValidator do
      describe "#call" do
        let(:errors) { [] }
        let(:column) { ColumnDefinition.new(name: :name, type: :string, max_length: 10) }

        it "adds no error when string is within max_length" do
          validator = described_class.new(value: "short", column: column, errors: errors)
          validator.call
          expect(errors).to be_empty
        end

        it "adds no error when string length equals max_length" do
          validator = described_class.new(value: "1234567890", column: column, errors: errors)
          validator.call
          expect(errors).to be_empty
        end

        it "adds error when string exceeds max_length" do
          validator = described_class.new(value: "this is too long", column: column, errors: errors)
          validator.call
          expect(errors).to eq([ "must be at most 10 characters" ])
        end

        it "adds no error when value is not a string" do
          validator = described_class.new(value: 42, column: column, errors: errors)
          validator.call
          expect(errors).to be_empty
        end

        it "includes max_length in error message" do
          col = ColumnDefinition.new(name: :code, type: :string, max_length: 5)
          validator = described_class.new(value: "abcdef", column: col, errors: errors)
          validator.call
          expect(errors).to eq([ "must be at most 5 characters" ])
        end
      end
    end
  end
end
