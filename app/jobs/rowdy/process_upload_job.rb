module Rowdy
  class ProcessUploadJob < ApplicationJob
    queue_as :rowdy_processing

    def perform(upload_id)
      result = ProcessUpload.call(upload_id: upload_id)

      raise result.message if result.failure?
    end
  end
end
