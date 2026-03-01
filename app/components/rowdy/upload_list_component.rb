module Rowdy
  class UploadListComponent < ViewComponent::Base
    def initialize(uploads: [], schema_name: nil)
      @uploads = uploads
      @schema_name = schema_name
    end

    def stream_channel
      @schema_name ? :"rowdy_uploads_#{@schema_name}" : :rowdy_uploads
    end

    def list_id
      @schema_name ? "rowdy-uploads-list-#{@schema_name}" : "rowdy-uploads-list"
    end
  end
end
