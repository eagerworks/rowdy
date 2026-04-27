module Rowdy
  class UploadListComponent < ViewComponent::Base
    attr_reader :uploads, :schema_name, :show_list_icon, :scrollable, :list_frame, :create_frame

    def initialize(uploads: [], schema_name: nil, scrollable: false, show_list_icon: false, list_frame: nil, create_frame: nil)
      @uploads = uploads
      @schema_name = schema_name
      @scrollable = scrollable
      @show_list_icon = show_list_icon
      @list_frame = list_frame
      @create_frame = create_frame
    end

    def stream_channel
      schema_name ? :"rowdy_uploads_#{schema_name}" : :rowdy_uploads
    end

    def list_id
      schema_name ? "rowdy-uploads-list-#{schema_name}" : "rowdy-uploads-list"
    end

    def scroll_container_id
      schema_name ? "rowdy-uploads-scroll-#{schema_name}" : "rowdy-uploads-scroll"
    end

    def list_items_id
      schema_name ? "rowdy-uploads-list-items-#{schema_name}" : "rowdy-uploads-list-items"
    end
  end
end
