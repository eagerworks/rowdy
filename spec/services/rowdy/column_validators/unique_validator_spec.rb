# frozen_string_literal: true

require "rails_helper"

module Rowdy
  module ColumnValidators
    RSpec.describe UniqueValidator do
      describe ".execute" do
        let(:errors) { [] }
        let(:column) { ColumnDefinition.new(name: :sku, type: :string, unique: true) }

        context "when unique_tracker is present" do
          it "adds no error when value is new" do
            tracker = UniqueTracker.new
            described_class.execute(value: "SKU-001", column: column, errors: errors, unique_tracker: tracker)
            expect(errors).to be_empty
          end

          it "adds error when value was already seen" do
            tracker = UniqueTracker.new
            tracker.add?(:sku, "SKU-001")
            described_class.execute(value: "SKU-001", column: column, errors: errors, unique_tracker: tracker)
            expect(errors).to eq([ "must be unique" ])
          end

          it "tracks by column name" do
            tracker = UniqueTracker.new
            tracker.add?(:name, "Duplicate")
            described_class.execute(value: "Duplicate", column: column, errors: errors, unique_tracker: tracker)
            expect(errors).to be_empty
          end
        end

        context "when unique_tracker is nil" do
          it "adds no error" do
            described_class.execute(value: "SKU-001", column: column, errors: errors, unique_tracker: nil)
            expect(errors).to be_empty
          end
        end
      end
    end
  end
end
