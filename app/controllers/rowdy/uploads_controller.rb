module Rowdy
  class UploadsController < ApplicationController
    def create
      upload_ids = []

      Array(params[:files]).each do |file|
        upload = Upload.create!(
          filename: file.original_filename,
          size: file.size,
          input_file: file
        )
        ProcessUploadJob.perform_later(upload.id)
        upload_ids << upload.id
      end

      render json: { upload_ids: upload_ids }, status: :created
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def show
      upload = Upload.find(params[:id])

      unless upload.completed?
        render json: { error: "Upload is not completed yet" }, status: :unprocessable_entity
        return
      end

      unless upload.output_file.attached?
        render json: { error: "Output file not found" }, status: :not_found
        return
      end

      redirect_to rails_blob_path(upload.output_file, disposition: "attachment")
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: e.message }, status: :not_found
    end
  end
end
