# frozen_string_literal: true

require "rails_helper"

module Rowdy
  module ColumnValidators
    RSpec.describe CustomValidator do
      describe ".execute" do
        let(:errors) { [] }

        it "runs each custom validation and appends to errors" do
          column = ColumnDefinition.new(name: :code, type: :string)
          column.validate { |val, errs| errs << "must start with X" unless val.to_s.start_with?("X") }

          described_class.execute(value: "ABC", column: column, errors: errors)
          expect(errors).to eq([ "must start with X" ])
        end

        it "adds no errors when custom validation passes" do
          column = ColumnDefinition.new(name: :code, type: :string)
          column.validate { |val, errs| errs << "invalid" unless val == "OK" }

          described_class.execute(value: "OK", column: column, errors: errors)
          expect(errors).to be_empty
        end

        it "runs all custom validations and collects all errors" do
          column = ColumnDefinition.new(name: :code, type: :string)
          column.validate { |val, errs| errs << "error one" if val.to_s.length < 2 }
          column.validate { |val, errs| errs << "error two" unless val.to_s.match?(/\A[A-Z]+\z/) }

          described_class.execute(value: "a", column: column, errors: errors)
          expect(errors).to contain_exactly("error one", "error two")
        end

        it "does nothing when column has no custom validations" do
          column = ColumnDefinition.new(name: :name, type: :string)
          described_class.execute(value: "anything", column: column, errors: errors)
          expect(errors).to be_empty
        end
      end
    end
  end
end
