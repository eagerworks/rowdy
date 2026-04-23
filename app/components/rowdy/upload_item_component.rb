module Rowdy
  class UploadItemComponent < ViewComponent::Base
    def initialize(upload:, show_list_icon: false)
      @upload = upload
      @show_list_icon = show_list_icon
    end

    def create_import_path
      Rowdy::Engine.routes.url_helpers.imports_path(upload_id: @upload.id)
    end

    def view_imports_path
      Rowdy::Engine.routes.url_helpers.imports_path(upload_id: @upload.id)
    end

    def importable?
      @upload.completed? && @upload.schema_name.present?
    end

    def steps_frame_id
      "rowdy-steps-#{@upload.schema_name}"
    end
  end
end
