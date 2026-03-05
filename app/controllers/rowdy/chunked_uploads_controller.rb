module Rowdy
  class ChunkedUploadsController < ApplicationController
    include ChunkedUploadHandling

    skip_forgery_protection only: :receive_chunk

    before_action :set_upload, only: %i[status receive_chunk complete]

    def initiate
      upload = InitiateUpload.call(
        filename: params[:filename],
        file_size: params[:size].to_i,
        chunk_size: params[:chunk_size],
        schema_name: params[:schema_name]
      )

      render json: {
        upload_token: upload.upload_token,
        total_chunks: upload.total_chunks,
        chunk_size: upload.chunk_size,
        received_chunks: []
      }, status: :created
    end

    def status
      render json: @upload.status_json
    end

    def receive_chunk
      result = ReceiveChunk.call(
        upload: @upload,
        chunk_index: params[:index].to_i,
        chunk_data: request.body.read
      )

      render json: {
        chunk_index: result.chunk_index,
        received_chunks: result.received_chunks,
        upload_progress_percent: result.upload_progress_percent
      }
    end

    def complete
      if (error = @upload.completion_error)
        render(**error)
        return
      end

      AssembleChunks.call(@upload)

      render json: @upload.completion_json
    end
  end
end
