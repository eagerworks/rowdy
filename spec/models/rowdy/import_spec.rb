require "rails_helper"

module Rowdy
  RSpec.describe Import, type: :model do
    describe "validations" do
      it "is valid with required attributes" do
        expect(build(:rowdy_import)).to be_valid
      end

      it "is invalid without schema_name" do
        import = build(:rowdy_import, schema_name: nil)
        expect(import).not_to be_valid
        expect(import.errors[:schema_name]).to include("can't be blank")
      end
    end

    describe "enums" do
      it "default status is mapping" do
        expect(create(:rowdy_import)).to be_mapping
      end

      it "supports all defined statuses" do
        %i[mapping validating validated importing imported failed preparing].each do |status|
          import = create(:rowdy_import, status: status)
          expect(import.public_send(:"#{status}?")).to be(true)
        end
      end
    end

    describe "associations" do
      it "belongs to an upload" do
        expect(create(:rowdy_import).upload).to be_a(Rowdy::Upload)
      end

      it "destroys import_errors on delete" do
        import = create(:rowdy_import)
        create(:rowdy_import_error, import: import)
        expect { import.destroy }.to change(Rowdy::ImportError, :count).by(-1)
      end
    end

    describe "#current_step" do
      it "is 1 when mapping" do
        expect(build(:rowdy_import, status: :mapping).current_step).to eq(1)
      end

      it "is 2 when validating" do
        expect(build(:rowdy_import, status: :validating).current_step).to eq(2)
      end

      it "is 2 when validated" do
        expect(build(:rowdy_import, status: :validated).current_step).to eq(2)
      end

      it "is 2 when preparing" do
        expect(build(:rowdy_import, status: :preparing).current_step).to eq(2)
      end

      it "is 3 when importing" do
        expect(build(:rowdy_import, status: :importing).current_step).to eq(3)
      end

      it "is 3 when imported" do
        expect(build(:rowdy_import, status: :imported).current_step).to eq(3)
      end

      context "when failed" do
        it "is 1 with no column_mapping" do
          import = build(:rowdy_import, status: :failed, column_mapping: nil)
          expect(import.current_step).to eq(1)
        end

        it "is 2 with mapping but zero total_rows" do
          import = build(:rowdy_import, status: :failed, column_mapping: { "name" => "name" }, total_rows: 0)
          expect(import.current_step).to eq(2)
        end

        it "is 3 with mapping and rows processed" do
          import = build(:rowdy_import, status: :failed, column_mapping: { "name" => "name" }, total_rows: 5)
          expect(import.current_step).to eq(3)
        end
      end
    end

    describe "#schema" do
      it "returns the registered schema class" do
        import = build(:rowdy_import, schema_name: "product_import")
        expect(import.schema).to eq(ProductImportSchema)
      end
    end

    describe "column_mapping serialization" do
      it "persists and retrieves as a hash" do
        mapping = { "name" => "name", "sku" => "sku" }
        import = create(:rowdy_import, column_mapping: mapping)
        expect(import.reload.column_mapping).to eq(mapping)
      end
    end
  end
end
