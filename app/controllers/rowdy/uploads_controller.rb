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
        ProcessUploadJob.perform_now(upload.id)
        upload_ids << upload.id
      end

      render json: { upload_ids: upload_ids }, status: :created
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end
