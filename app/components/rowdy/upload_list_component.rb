module Rowdy
  class UploadListComponent < ViewComponent::Base
    attr_reader :uploads, :schema_name, :scrollable

    def initialize(uploads: [], schema_name: nil, scrollable: false)
      @uploads = uploads
      @schema_name = schema_name
      @scrollable = scrollable
    end

    def stream_channel
      schema_name ? :"rowdy_uploads_#{schema_name}" : :rowdy_uploads
    end

    def list_id
      schema_name ? "rowdy-uploads-list-#{schema_name}" : "rowdy-uploads-list"
    end

    def scroll_container_id
      schema_name ? "rowdy-uploads-list-items-#{schema_name}" : "rowdy-uploads-list-items"
    end
  end
end
