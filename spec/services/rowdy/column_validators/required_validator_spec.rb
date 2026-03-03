# frozen_string_literal: true

require "rails_helper"

module Rowdy
  module ColumnValidators
    RSpec.describe RequiredValidator do
      describe ".call" do
        let(:errors) { [] }
        let(:required_column) { ColumnDefinition.new(name: :name, type: :string, required: true) }
        let(:optional_column) { ColumnDefinition.new(name: :nickname, type: :string, required: false) }

        context "when column is required" do
          it "adds an error when value is nil" do
            described_class.call(nil, required_column, errors)
            expect(errors).to eq([ "is required" ])
          end

          it "adds an error when value is blank string" do
            described_class.call("", required_column, errors)
            expect(errors).to eq([ "is required" ])
          end

          it "adds an error when value is whitespace-only string" do
            described_class.call("   ", required_column, errors)
            expect(errors).to eq([ "is required" ])
          end

          it "does not add an error when value is present" do
            described_class.call("Alice", required_column, errors)
            expect(errors).to be_empty
          end

          it "does not add an error when value is non-empty string with spaces" do
            described_class.call("  hello  ", required_column, errors)
            expect(errors).to be_empty
          end
        end

        context "when column is optional" do
          it "does not add an error when value is nil" do
            described_class.call(nil, optional_column, errors)
            expect(errors).to be_empty
          end

          it "does not add an error when value is blank" do
            described_class.call("  ", optional_column, errors)
            expect(errors).to be_empty
          end
        end
      end

      describe ".blank?" do
        it "returns true for nil" do
          expect(described_class.blank?(nil)).to be true
        end

        it "returns true for empty string" do
          expect(described_class.blank?("")).to be true
        end

        it "returns true for whitespace-only string" do
          expect(described_class.blank?("   ")).to be true
        end

        it "returns false for non-blank string" do
          expect(described_class.blank?("x")).to be false
        end

        it "returns false for non-string values" do
          expect(described_class.blank?(0)).to be false
          expect(described_class.blank?(false)).to be false
        end
      end
    end
  end
end
