require "rails_helper"

module Rowdy
  RSpec.describe "ChunkedUploads", type: :request do
    describe "POST /rowdy/chunked_uploads" do
      context "with valid params" do
        it "returns 201 with upload metadata" do
          post "/rowdy/chunked_uploads", params: { filename: "data.xlsx", size: 1000, chunk_size: 300 }
          expect(response).to have_http_status(:created)
          body = JSON.parse(response.body)
          expect(body["upload_token"]).to be_present
          expect(body["total_chunks"]).to eq(4)
          expect(body["received_chunks"]).to eq([])
        end
      end
    end

    describe "GET /rowdy/chunked_uploads/:token" do
      context "when the token exists" do
        it "returns upload info" do
          upload = InitiateUpload.call(filename: "data.xlsx", file_size: 500, chunk_size: 200)
          get "/rowdy/chunked_uploads/#{upload.upload_token}"

          expect(response).to have_http_status(:ok)
          body = JSON.parse(response.body)
          expect(body["upload_token"]).to eq(upload.upload_token)
          expect(body["status"]).to eq("uploading")
        ensure
          ChunkStorage.cleanup(upload&.chunks_dir)
        end
      end

      context "when the token does not exist" do
        it "returns 404" do
          get "/rowdy/chunked_uploads/nonexistent_token"
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe "PUT /rowdy/chunked_uploads/:token/:index" do
      context "with a valid chunk" do
        it "stores the chunk and returns progress" do
          upload = InitiateUpload.call(filename: "data.xlsx", file_size: 300, chunk_size: 100)
          put "/rowdy/chunked_uploads/#{upload.upload_token}/0",
            params: "A" * 100,
            headers: { "CONTENT_TYPE" => "application/octet-stream" }

          expect(response).to have_http_status(:ok)
          body = JSON.parse(response.body)
          expect(body["received_chunks"]).to include(0)
        ensure
          ChunkStorage.cleanup(upload&.chunks_dir)
        end

        it "is idempotent when receiving the same chunk twice" do
          upload = InitiateUpload.call(filename: "data.xlsx", file_size: 300, chunk_size: 100)
          2.times do
            put "/rowdy/chunked_uploads/#{upload.upload_token}/0",
              params: "A" * 100,
              headers: { "CONTENT_TYPE" => "application/octet-stream" }
            expect(response).to have_http_status(:ok)
          end
        ensure
          ChunkStorage.cleanup(upload&.chunks_dir)
        end
      end

      context "with an invalid chunk index" do
        it "returns 400" do
          upload = InitiateUpload.call(filename: "data.xlsx", file_size: 300, chunk_size: 100)
          put "/rowdy/chunked_uploads/#{upload.upload_token}/99",
            params: "data",
            headers: { "CONTENT_TYPE" => "application/octet-stream" }

          expect(response).to have_http_status(:bad_request)
        ensure
          ChunkStorage.cleanup(upload&.chunks_dir)
        end
      end

      context "when the upload is not in uploading status" do
        it "returns 409" do
          upload = InitiateUpload.call(filename: "data.xlsx", file_size: 300, chunk_size: 100)
          upload.update_column(:status, Upload.statuses[:pending])

          put "/rowdy/chunked_uploads/#{upload.upload_token}/0",
            params: "data",
            headers: { "CONTENT_TYPE" => "application/octet-stream" }

          expect(response).to have_http_status(:conflict)
        ensure
          ChunkStorage.cleanup(upload&.chunks_dir)
        end
      end
    end

    describe "POST /rowdy/chunked_uploads/:token/complete" do
      before { allow(ProcessUploadJob).to receive(:perform_now) }

      context "when all chunks are present" do
        it "assembles the file and returns upload_id" do
          upload = InitiateUpload.call(filename: "data.xlsx", file_size: 30, chunk_size: 10)
          ChunkStorage.write_chunk(upload.chunks_dir, 0, "AAAAAAAAAA")
          ChunkStorage.write_chunk(upload.chunks_dir, 1, "BBBBBBBBBB")
          ChunkStorage.write_chunk(upload.chunks_dir, 2, "CCCCCCCCCC")
          upload.update!(received_chunks: [ 0, 1, 2 ])

          post "/rowdy/chunked_uploads/#{upload.upload_token}/complete"

          expect(response).to have_http_status(:ok)
          body = JSON.parse(response.body)
          expect(body["upload_id"]).to eq(upload.id)
        end
      end

      context "when chunks are missing" do
        it "returns 422" do
          upload = InitiateUpload.call(filename: "data.xlsx", file_size: 30, chunk_size: 10)
          ChunkStorage.write_chunk(upload.chunks_dir, 0, "AAAAAAAAAA")
          upload.update!(received_chunks: [ 0 ])

          post "/rowdy/chunked_uploads/#{upload.upload_token}/complete"

          expect(response).to have_http_status(:unprocessable_entity)
        ensure
          ChunkStorage.cleanup(upload&.chunks_dir)
        end
      end
    end
  end
end
