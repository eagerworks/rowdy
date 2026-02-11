module Rowdy
  class UploadListComponent < ViewComponent::Base
    def initialize(uploads: [])
      @uploads = uploads
    end
  end
end
