require "rails_helper"

module Rowdy
  RSpec.describe ImportError, type: :model do
    describe "validations" do
      it "is valid with required attributes" do
        expect(build(:rowdy_import_error)).to be_valid
      end

      it "is invalid without row_number" do
        error = build(:rowdy_import_error, row_number: nil)
        expect(error).not_to be_valid
        expect(error.errors[:row_number]).to include("can't be blank")
      end
    end

    describe "associations" do
      it "belongs to an import" do
        expect(build(:rowdy_import_error).import).to be_a(Rowdy::Import)
      end
    end

    describe ".active" do
      it "includes errors without corrected_at" do
        error = create(:rowdy_import_error)
        expect(described_class.active).to include(error)
      end

      it "excludes errors with corrected_at set" do
        error = create(:rowdy_import_error, :corrected)
        expect(described_class.active).not_to include(error)
      end
    end

    describe ".corrected" do
      it "includes errors with corrected_at set" do
        error = create(:rowdy_import_error, :corrected)
        expect(described_class.corrected).to include(error)
      end

      it "excludes errors without corrected_at" do
        error = create(:rowdy_import_error)
        expect(described_class.corrected).not_to include(error)
      end
    end

    describe "serialization" do
      it "serializes column_errors as JSON hash" do
        data = { "sku" => [ "is required" ], "price" => [ "must be greater than 0" ] }
        error = create(:rowdy_import_error, column_errors: data)
        expect(error.reload.column_errors).to eq(data)
      end

      it "serializes row_data as JSON hash" do
        row = { "name" => "T-Shirt", "sku" => nil, "price" => "bad" }
        error = create(:rowdy_import_error, row_data: row)
        expect(error.reload.row_data).to eq(row)
      end
    end
  end
end
