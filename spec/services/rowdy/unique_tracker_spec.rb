require "rails_helper"

module Rowdy
  RSpec.describe UniqueTracker do
    subject(:tracker) { described_class.new }

    describe "#add?" do
      it "returns true for a new value" do
        expect(tracker.add?(:sku, "ABC123")).to be(true)
      end

      it "returns false for a duplicate value in the same column" do
        tracker.add?(:sku, "ABC123")
        expect(tracker.add?(:sku, "ABC123")).to be(false)
      end

      it "tracks different columns independently" do
        expect(tracker.add?(:sku, "ABC123")).to be(true)
        expect(tracker.add?(:name, "ABC123")).to be(true)
      end

      it "returns true for different values in the same column" do
        tracker.add?(:sku, "ABC123")
        expect(tracker.add?(:sku, "XYZ789")).to be(true)
      end
    end

    describe "#size_for" do
      it "returns 0 for unseen column" do
        expect(tracker.size_for(:sku)).to eq(0)
      end

      it "returns count of unique values added" do
        tracker.add?(:sku, "A")
        tracker.add?(:sku, "B")
        tracker.add?(:sku, "A")
        expect(tracker.size_for(:sku)).to eq(2)
      end

      it "is independent per column" do
        tracker.add?(:sku, "A")
        tracker.add?(:name, "A")
        tracker.add?(:name, "B")
        expect(tracker.size_for(:sku)).to eq(1)
        expect(tracker.size_for(:name)).to eq(2)
      end
    end
  end
end
