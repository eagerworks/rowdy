require "rails_helper"

module Rowdy
  # ProductImportSchema columns:
  #   name:     string, required, max_length: 100
  #   sku:      string, required, unique
  #   price:    decimal, required, greater_than: 0
  #   stock:    integer, optional
  #   category: string, optional, inclusion: %w[electronics clothing food other]
  RSpec.describe ReplaceAll do
    let(:import) do
      create(:rowdy_import, :validated,
             invalid_rows_count: 1,
             valid_rows_count:   9)
    end

    def errored_row(category:)
      create(:rowdy_import_error,
             import:        import,
             row_number:    2,
             row_data:      { "name" => "T-Shirt", "sku" => "SKU1", "price" => "19.99",
                              "stock" => "10", "category" => category },
             column_errors: { "category" => [ "must be one of: electronics, clothing, food, other" ] })
    end

    def call(**opts)
      defaults = { import: import, column: "category", find_value: "ios",
                   replace_value: "other", case_sensitive: true, exact_match: true }
      described_class.call(**defaults.merge(opts))
    end

    describe "matching modes" do
      describe "exact match + case sensitive (default)" do
        it "replaces when value matches exactly" do
          error = errored_row(category: "ios")
          call
          expect(error.reload.row_data["category"]).to eq("other")
        end

        it "does not replace when case differs" do
          error = errored_row(category: "IOS")
          call
          expect(error.reload.row_data["category"]).to eq("IOS")
        end

        it "does not replace when value is a substring match only" do
          error = errored_row(category: "ios_extra")
          call
          expect(error.reload.row_data["category"]).to eq("ios_extra")
        end
      end

      describe "exact match + case insensitive" do
        it "replaces when value matches regardless of case" do
          error = errored_row(category: "IOS")
          call(find_value: "ios", case_sensitive: false, exact_match: true)
          expect(error.reload.row_data["category"]).to eq("other")
        end

        it "does not replace when value is a partial match" do
          error = errored_row(category: "ios_extra")
          call(find_value: "ios", case_sensitive: false, exact_match: true)
          expect(error.reload.row_data["category"]).to eq("ios_extra")
        end
      end

      describe "substring match + case sensitive" do
        it "replaces when find_value is contained in the cell" do
          error = errored_row(category: "ios")
          call(find_value: "io", case_sensitive: true, exact_match: false)
          expect(error.reload.row_data["category"]).to eq("other")
        end

        it "does not replace when case differs" do
          error = errored_row(category: "IOS")
          call(find_value: "io", case_sensitive: true, exact_match: false)
          expect(error.reload.row_data["category"]).to eq("IOS")
        end
      end

      describe "substring match + case insensitive" do
        it "replaces when find_value matches as a substring regardless of case" do
          error = errored_row(category: "IOS")
          call(find_value: "io", case_sensitive: false, exact_match: false)
          expect(error.reload.row_data["category"]).to eq("other")
        end
      end

      describe "all empty cells" do
        it "replaces when value is an empty string" do
          error = errored_row(category: "")
          call(all_empty: true, find_value: "")
          expect(error.reload.row_data["category"]).to eq("other")
        end

        it "replaces when value is only whitespace" do
          error = errored_row(category: "   ")
          call(all_empty: true, find_value: "")
          expect(error.reload.row_data["category"]).to eq("other")
        end

        it "does not replace when value is not blank" do
          error = errored_row(category: "ios")
          call(all_empty: true, find_value: "")
          expect(error.reload.row_data["category"]).to eq("ios")
        end
      end
    end

    describe "re-validation after replacement" do
      context "when replacement makes the row valid" do
        it "sets corrected_at" do
          error = errored_row(category: "ios")
          expect { call }.to change { error.reload.corrected_at }.from(nil)
        end

        it "increments valid_rows_count and decrements invalid_rows_count" do
          errored_row(category: "ios")
          expect { call }
            .to  change { import.reload.valid_rows_count }.by(1)
            .and change { import.reload.invalid_rows_count }.by(-1)
        end
      end

      context "when replacement still has validation errors" do
        it "updates row_data but does not set corrected_at" do
          error = errored_row(category: "ios")
          call(replace_value: "still_invalid")
          error.reload
          expect(error.row_data["category"]).to eq("still_invalid")
          expect(error.corrected_at).to be_nil
        end

        it "updates column_errors with the new validation result" do
          error = errored_row(category: "ios")
          call(replace_value: "still_invalid")
          expect(error.reload.column_errors["category"]).to be_present
        end

        it "does not change import row counts" do
          errored_row(category: "ios")
          expect { call(replace_value: "still_invalid") }
            .not_to change { import.reload.valid_rows_count }
          expect { call(replace_value: "still_invalid") }
            .not_to change { import.reload.invalid_rows_count }
        end
      end
    end

    describe "scope" do
      it "does not affect rows from other imports" do
        other_import = create(:rowdy_import, :validated)
        other_error  = create(:rowdy_import_error,
                               import:        other_import,
                               row_data:      { "name" => "X", "sku" => "SKU2", "price" => "5.00",
                                                "stock" => "1", "category" => "ios" },
                               column_errors: { "category" => [ "must be one of: electronics, clothing, food, other" ] })
        call
        expect(other_error.reload.corrected_at).to be_nil
      end

      it "does not affect rows where the column has no errors" do
        error = create(:rowdy_import_error,
                        import:        import,
                        row_data:      { "name" => nil, "sku" => "SKU3", "price" => "5.00",
                                         "stock" => "1", "category" => "ios" },
                        column_errors: { "name" => [ "is required" ] })
        call
        expect(error.reload.corrected_at).to be_nil
        expect(error.reload.row_data["category"]).to eq("ios")
      end

      it "does not affect already corrected rows" do
        error = errored_row(category: "ios")
        error.update!(corrected_at: 1.hour.ago)
        call
        original_corrected_at = error.corrected_at
        expect(error.reload.corrected_at).to be_within(1.second).of(original_corrected_at)
      end

      it "replaces all matching rows when multiple exist" do
        error1 = errored_row(category: "ios")
        error2 = create(:rowdy_import_error,
                         import:        import,
                         row_number:    3,
                         row_data:      { "name" => "Hoodie", "sku" => "SKU4", "price" => "39.99",
                                          "stock" => "5", "category" => "ios" },
                         column_errors: { "category" => [ "must be one of: electronics, clothing, food, other" ] })
        import.update!(invalid_rows_count: 2, valid_rows_count: 8)

        call
        expect(error1.reload.corrected_at).not_to be_nil
        expect(error2.reload.corrected_at).not_to be_nil
        expect(import.reload.invalid_rows_count).to eq(0)
        expect(import.reload.valid_rows_count).to eq(10)
      end
    end
  end
end
