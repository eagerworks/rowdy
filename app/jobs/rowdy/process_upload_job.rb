module Rowdy
  class ProcessUploadJob < ApplicationJob
    queue_as :rowdy_processing

    def perform(upload_id)
      result = ProcessUpload.call(upload_id: upload_id)

      if result.failure?
        Upload.find_by(id: upload_id)&.update!(status: :failed)
      end
    end
  end
end
