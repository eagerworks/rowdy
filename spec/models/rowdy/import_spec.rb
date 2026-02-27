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
      it "defaults to mapping status" do
        expect(build(:rowdy_import)).to be_mapping
      end

      context "when status is mapping" do
        it "responds to mapping?" do
          expect(build(:rowdy_import, status: :mapping)).to be_mapping
        end
      end

      context "when status is validating" do
        it "responds to validating?" do
          expect(build(:rowdy_import, status: :validating)).to be_validating
        end
      end

      context "when status is validated" do
        it "responds to validated?" do
          expect(build(:rowdy_import, status: :validated)).to be_validated
        end
      end

      context "when status is importing" do
        it "responds to importing?" do
          expect(build(:rowdy_import, status: :importing)).to be_importing
        end
      end

      context "when status is imported" do
        it "responds to imported?" do
          expect(build(:rowdy_import, status: :imported)).to be_imported
        end
      end

      context "when status is failed" do
        it "responds to failed?" do
          expect(build(:rowdy_import, status: :failed)).to be_failed
        end
      end

      context "when status is preparing" do
        it "responds to preparing?" do
          expect(build(:rowdy_import, status: :preparing)).to be_preparing
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
      context "when status is mapping" do
        it "returns step 1" do
          expect(build(:rowdy_import, status: :mapping).current_step).to eq(1)
        end
      end

      context "when status is validating" do
        it "returns step 2" do
          expect(build(:rowdy_import, status: :validating).current_step).to eq(2)
        end
      end

      context "when status is validated" do
        it "returns step 2" do
          expect(build(:rowdy_import, status: :validated).current_step).to eq(2)
        end
      end

      context "when status is preparing" do
        it "returns step 2" do
          expect(build(:rowdy_import, status: :preparing).current_step).to eq(2)
        end
      end

      context "when status is importing" do
        it "returns step 3" do
          expect(build(:rowdy_import, status: :importing).current_step).to eq(3)
        end
      end

      context "when status is imported" do
        it "returns step 3" do
          expect(build(:rowdy_import, status: :imported).current_step).to eq(3)
        end
      end

      context "when status is failed" do
        context "when column_mapping is nil" do
          it "returns step 1" do
            import = build(:rowdy_import, status: :failed, column_mapping: nil)
            expect(import.current_step).to eq(1)
          end
        end

        context "when column_mapping is present but total_rows is zero" do
          it "returns step 2" do
            import = build(:rowdy_import, status: :failed, column_mapping: { "name" => "name" }, total_rows: 0)
            expect(import.current_step).to eq(2)
          end
        end

        context "when column_mapping is present and total_rows is positive" do
          it "returns step 3" do
            import = build(:rowdy_import, status: :failed, column_mapping: { "name" => "name" }, total_rows: 5)
            expect(import.current_step).to eq(3)
          end
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
