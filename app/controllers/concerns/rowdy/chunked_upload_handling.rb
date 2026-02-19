module Rowdy
  module ChunkedUploadHandling
    extend ActiveSupport::Concern

    included do
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ReceiveChunk::UploadNotUploadingError, with: :render_conflict
      rescue_from ReceiveChunk::InvalidChunkIndexError, with: :render_bad_request
    end

    private

    def set_upload
      @upload = Upload.find_by!(upload_token: params[:token])
    end

    def render_not_found(exception)
      render json: { error: exception.message }, status: :not_found
    end

    def render_conflict(exception)
      render json: { error: exception.message }, status: :conflict
    end

    def render_bad_request(exception)
      render json: { error: exception.message }, status: :bad_request
    end
  end
end
