module Rowdy
  class DropzoneComponent < ViewComponent::Base
    def initialize(
      url: nil,
      label: nil,
      accept: ".xlsx,.xls",
      multiple: true,
      **html_options
    )
      @url = url
      @label = label
      @accept = accept
      @multiple = multiple
      @html_options = html_options
    end

    def dropzone_url
      @url || Rowdy::Engine.routes.url_helpers.uploads_path
    end

    def label_text
      @label || I18n.t("rowdy.dropzone.label")
    end
  end
end
