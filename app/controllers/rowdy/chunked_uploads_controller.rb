module Rowdy
  class ChunkedUploadsController < ApplicationController
    skip_forgery_protection only: :receive_chunk

    def initiate
      chunk_size = (params[:chunk_size] || Rowdy.configuration.default_chunk_size).to_i
      file_size = params[:size].to_i
      total_chunks = (file_size.to_f / chunk_size).ceil

      upload = Upload.create!(
        filename: params[:filename],
        size: file_size,
        status: :uploading,
        total_chunks: total_chunks,
        chunk_size: chunk_size
      )

      dir = ChunkStorage.create_dir(upload.upload_token)
      upload.update!(chunks_dir: dir)

      render json: {
        upload_token: upload.upload_token,
        total_chunks: total_chunks,
        chunk_size: chunk_size,
        received_chunks: []
      }, status: :created
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def status
      upload = Upload.find_by!(upload_token: params[:token])

      render json: {
        upload_token: upload.upload_token,
        status: upload.status,
        total_chunks: upload.total_chunks,
        received_chunks: upload.received_chunks,
        upload_progress_percent: upload.upload_progress_percent
      }
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Upload not found" }, status: :not_found
    end

    def receive_chunk
      upload = Upload.find_by!(upload_token: params[:token])
      chunk_index = params[:index].to_i

      unless upload.uploading?
        render json: { error: "Upload is not in uploading state" }, status: :conflict
        return
      end

      if chunk_index.negative? || chunk_index >= upload.total_chunks
        render json: { error: "Invalid chunk index" }, status: :bad_request
        return
      end

      if upload.received_chunks.include?(chunk_index)
        render json: {
          chunk_index: chunk_index,
          received_chunks: upload.received_chunks,
          upload_progress_percent: upload.upload_progress_percent
        }
        return
      end

      ChunkStorage.write_chunk(upload.chunks_dir, chunk_index, request.body.read)

      upload.with_lock do
        upload.reload
        upload.received_chunks << chunk_index
        upload.save!
      end

      render json: {
        chunk_index: chunk_index,
        received_chunks: upload.received_chunks,
        upload_progress_percent: upload.upload_progress_percent
      }
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Upload not found" }, status: :not_found
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def complete
      upload = Upload.find_by!(upload_token: params[:token])

      unless upload.uploading?
        render json: { error: "Upload is not in uploading state" }, status: :conflict
        return
      end

      unless upload.all_chunks_received?
        missing = (0...upload.total_chunks).to_a - upload.received_chunks
        render json: {
          error: "Missing chunks: #{missing}",
          received_chunks: upload.received_chunks
        }, status: :unprocessable_entity
        return
      end

      AssembleChunks.call(upload)

      render json: {
        upload_id: upload.id,
        status: upload.reload.status,
        message: "Upload complete, processing queued"
      }
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Upload not found" }, status: :not_found
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end
