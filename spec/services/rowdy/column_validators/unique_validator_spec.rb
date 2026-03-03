# frozen_string_literal: true

require "rails_helper"

module Rowdy
  module ColumnValidators
    RSpec.describe UniqueValidator do
      describe "#call" do
        let(:errors) { [] }
        let(:column) { ColumnDefinition.new(name: :sku, type: :string, unique: true) }

        context "when unique_tracker is present" do
          it "adds no error when value is new" do
            tracker = UniqueTracker.new
            validator = described_class.new(value: "SKU-001", column: column, errors: errors, unique_tracker: tracker)
            validator.call
            expect(errors).to be_empty
          end

          it "adds error when value was already seen" do
            tracker = UniqueTracker.new
            tracker.add?(:sku, "SKU-001")
            validator = described_class.new(value: "SKU-001", column: column, errors: errors, unique_tracker: tracker)
            validator.call
            expect(errors).to eq([ "must be unique" ])
          end

          it "tracks by column name" do
            tracker = UniqueTracker.new
            tracker.add?(:name, "Duplicate")
            validator = described_class.new(value: "Duplicate", column: column, errors: errors, unique_tracker: tracker)
            validator.call
            expect(errors).to be_empty
          end
        end

        context "when unique_tracker is nil" do
          it "adds no error" do
            validator = described_class.new(value: "SKU-001", column: column, errors: errors, unique_tracker: nil)
            validator.call
            expect(errors).to be_empty
          end
        end
      end
    end
  end
end
