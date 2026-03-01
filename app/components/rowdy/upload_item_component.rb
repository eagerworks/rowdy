module Rowdy
  class UploadItemComponent < ViewComponent::Base
    def initialize(upload:)
      @upload = upload
    end

    def create_import_path
      Rowdy::Engine.routes.url_helpers.imports_path(upload_id: @upload.id)
    end

    def importable?
      @upload.completed? && @upload.schema_name.present?
    end
  end
end
