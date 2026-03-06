require "rails_helper"

module Rowdy
  RSpec.describe "Imports", type: :request do
    describe "POST /rowdy/imports" do
      it "creates an import and redirects to mapping" do
        upload = create(:rowdy_upload, :completed, :with_schema, :with_columns)

        post "/rowdy/imports", params: { upload_id: upload.id }

        expect(response).to be_redirect
        import = upload.imports.last
        expect(import).to be_mapping
        expect(response).to redirect_to(/mapping/)
      end
    end

    describe "GET /rowdy/imports/:id/mapping" do
      it "returns 200 with the mapping page" do
        upload = create(:rowdy_upload, :completed, :with_schema, :with_columns)
        import = create(:rowdy_import, upload: upload)

        get "/rowdy/imports/#{import.id}/mapping"

        expect(response).to have_http_status(:ok)
      end
    end

    describe "PATCH /rowdy/imports/:id/save_mapping" do
      context "with a valid mapping" do
        it "redirects to the validation page and transitions to preparing" do
          upload = create(:rowdy_upload, :completed, :with_schema, :with_columns,
            detected_columns: %w[name sku price])
          import = create(:rowdy_import, upload: upload)

          patch "/rowdy/imports/#{import.id}/save_mapping", params: {
            column_mapping: { "name" => "name", "sku" => "sku", "price" => "price" }
          }

          expect(response).to be_redirect
          expect(import.reload).to be_preparing
          expect(response).to redirect_to(/validation/)
        end
      end

      context "when a required column is missing from the mapping" do
        it "returns 422" do
          upload = create(:rowdy_upload, :completed, :with_schema, :with_columns,
            detected_columns: %w[name sku price])
          import = create(:rowdy_import, upload: upload)

          patch "/rowdy/imports/#{import.id}/save_mapping", params: {
            column_mapping: { "name" => "name" }
          }

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe "POST /rowdy/imports/:id/validate" do
      it "returns 204 and triggers the validation job" do
        import = create(:rowdy_import, :with_mapping)
        allow(ValidateImportJob).to receive(:perform_now)

        post "/rowdy/imports/#{import.id}/validate"

        expect(response).to have_http_status(:no_content)
      end
    end

    describe "GET /rowdy/imports/:id/validation" do
      it "returns 200 with the validation page" do
        import = create(:rowdy_import, :validated)

        get "/rowdy/imports/#{import.id}/validation"

        expect(response).to have_http_status(:ok)
      end

      it "paginates import_errors" do
        import = create(:rowdy_import, :validated, invalid_rows_count: 2)
        create_list(:rowdy_import_error, 2, import: import)

        get "/rowdy/imports/#{import.id}/validation", params: { page: 1 }

        expect(response).to have_http_status(:ok)
      end

      it "excludes corrected errors from the response" do
        import = create(:rowdy_import, :validated, invalid_rows_count: 1)
        create(:rowdy_import_error, :corrected, import: import,
          row_data: { "name" => "T-Shirt", "sku" => "CORRECTED_VALUE" })

        get "/rowdy/imports/#{import.id}/validation"

        expect(response.body).not_to include("CORRECTED_VALUE")
      end
    end

    describe "PATCH /rowdy/imports/:id/correct_errors" do
      # row_data includes all required ProductImportSchema fields so re-validation
      # can produce a clean pass or fail depending on what the user corrects.
      let(:valid_row_data) { { "name" => "T-Shirt", "sku" => nil, "price" => "19.99" } }

      context "when the corrected value passes validation" do
        it "soft-deletes the import_error by setting corrected_at" do
          import = create(:rowdy_import, :validated, invalid_rows_count: 1, valid_rows_count: 9)
          error = create(:rowdy_import_error, import: import, row_data: valid_row_data,
            column_errors: { "sku" => [ "Is required" ] })

          freeze_time do
            patch "/rowdy/imports/#{import.id}/correct_errors", params: {
              corrections: { error.id.to_s => { "sku" => "ABC123" } }
            }

            expect(error.reload.corrected_at).to eq(Time.current)
          end
        end

        it "decrements invalid_rows_count and increments valid_rows_count" do
          import = create(:rowdy_import, :validated, invalid_rows_count: 1, valid_rows_count: 9)
          error = create(:rowdy_import_error, import: import, row_data: valid_row_data,
            column_errors: { "sku" => [ "Is required" ] })

          patch "/rowdy/imports/#{import.id}/correct_errors", params: {
            corrections: { error.id.to_s => { "sku" => "ABC123" } }
          }

          import.reload
          expect(import.invalid_rows_count).to eq(0)
          expect(import.valid_rows_count).to eq(10)
        end

        it "redirects to the validation page preserving the page param" do
          import = create(:rowdy_import, :validated, invalid_rows_count: 1, valid_rows_count: 9)
          error = create(:rowdy_import_error, import: import, row_data: valid_row_data)

          patch "/rowdy/imports/#{import.id}/correct_errors", params: {
            page: 2,
            corrections: { error.id.to_s => { "sku" => "ABC123" } }
          }

          expect(response).to redirect_to(/validation.*page=2/)
        end
      end

      context "when the corrected value still fails validation" do
        it "does not set corrected_at" do
          import = create(:rowdy_import, :validated)
          error = create(:rowdy_import_error, import: import, row_data: valid_row_data,
            column_errors: { "sku" => [ "Is required" ] })

          patch "/rowdy/imports/#{import.id}/correct_errors", params: {
            corrections: { error.id.to_s => { "sku" => "  " } }
          }

          expect(error.reload.corrected_at).to be_nil
        end

        it "updates row_data and column_errors with the new values" do
          import = create(:rowdy_import, :validated)
          error = create(:rowdy_import_error, import: import, row_data: valid_row_data,
            column_errors: { "sku" => [ "Is required" ] })

          patch "/rowdy/imports/#{import.id}/correct_errors", params: {
            corrections: { error.id.to_s => { "sku" => "  " } }
          }

          error.reload
          expect(error.row_data["sku"]).to eq("  ")
          expect(error.column_errors["sku"]).to be_present
        end

        it "redirects to the validation page" do
          import = create(:rowdy_import, :validated)
          error = create(:rowdy_import_error, import: import, row_data: valid_row_data)

          patch "/rowdy/imports/#{import.id}/correct_errors", params: {
            corrections: { error.id.to_s => { "sku" => "  " } }
          }

          expect(response).to redirect_to(/validation/)
        end
      end

      context "when corrections is empty" do
        it "redirects to the validation page without errors" do
          import = create(:rowdy_import, :validated)

          patch "/rowdy/imports/#{import.id}/correct_errors", params: { corrections: {} }

          expect(response).to redirect_to(/validation/)
        end
      end

      context "when the error_id does not belong to the import" do
        it "ignores the correction" do
          import = create(:rowdy_import, :validated)
          other_import = create(:rowdy_import, :validated)
          other_error = create(:rowdy_import_error, import: other_import)

          patch "/rowdy/imports/#{import.id}/correct_errors", params: {
            corrections: { other_error.id.to_s => { "sku" => "ABC123" } }
          }

          expect(other_error.reload.corrected_at).to be_nil
        end
      end
    end
  end
end
