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
    end
  end
end
