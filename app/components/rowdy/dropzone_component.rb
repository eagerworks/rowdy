module Rowdy
  class DropzoneComponent < ViewComponent::Base
    attr_reader :url, :label, :accept, :multiple, :chunked, :chunk_size, :schema_name, :html_options, :show_file_list

    def initialize(
      url: nil,
      label: nil,
      accept: ".xlsx,.xls",
      multiple: true,
      chunked: true,
      chunk_size: nil,
      schema_name: nil,
      show_file_list: false,
      **html_options
    )
      @url = url
      @label = label
      @accept = accept
      @multiple = multiple
      @chunked = chunked
      @show_file_list = show_file_list
      @chunk_size = chunk_size
      @schema_name = schema_name
      @html_options = html_options
    end

    def dropzone_url
      url || Rowdy::Engine.routes.url_helpers.uploads_path
    end

    def label_text
      label || I18n.t("rowdy.dropzone.label")
    end

    def chunked?
      chunked
    end

    def chunked_upload_url
      Rowdy::Engine.routes.url_helpers.chunked_uploads_path
    end

    def worker_url
      ActionController::Base.helpers.asset_path("rowdy/upload_worker.js")
    end

    def chunk_size_value
      chunk_size || Rowdy.configuration.default_chunk_size
    end
  end
end
