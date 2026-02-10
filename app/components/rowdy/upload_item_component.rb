module Rowdy
  class UploadItemComponent < ViewComponent::Base
    def initialize(upload:)
      @upload = upload
    end

    def download_path
      Rowdy::Engine.routes.url_helpers.upload_path(@upload)
    end
  end
end
