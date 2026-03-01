require "rails_helper"

module Rowdy
  RSpec.describe "Uploads", type: :request do
    def xlsx_upload(name = "test.xlsx")
      xlsx = create_test_xlsx(headers: %w[name sku price], rows: [ [ "T-Shirt", "SKU1", "9.99" ] ])
      Rack::Test::UploadedFile.new(
        xlsx.path,
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        true,
        original_filename: name
      )
    end

    before { allow(ProcessUploadJob).to receive(:perform_now) }

    describe "POST /rowdy/uploads" do
      it "returns 201 with upload_ids for a single file" do
        post "/rowdy/uploads", params: { files: [ xlsx_upload ] }
        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body["upload_ids"]).to be_an(Array)
        expect(body["upload_ids"].size).to eq(1)
      end

      it "returns multiple upload_ids for multiple files" do
        post "/rowdy/uploads", params: { files: [ xlsx_upload("a.xlsx"), xlsx_upload("b.xlsx") ] }
        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body["upload_ids"].size).to eq(2)
      end

      it "returns empty upload_ids when no files param is provided" do
        post "/rowdy/uploads", params: {}
        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body["upload_ids"]).to be_empty
      end
    end
  end
end
