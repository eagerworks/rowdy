module Rowdy
  class UploadItemComponent < ViewComponent::Base
    attr_accessor :upload, :show_list_icon, :list_turbo_frame, :create_turbo_frame, :hide_imported

    def initialize(upload:, show_list_icon: false, list_frame: nil, create_frame: nil, hide_imported: false)
      @upload = upload
      @show_list_icon = show_list_icon
      @list_turbo_frame = list_frame
      @create_turbo_frame = create_frame
      @hide_imported = hide_imported
    end

    def create_import_path
      Rowdy::Engine.routes.url_helpers.imports_path(upload_id: @upload.id)
    end

    def view_imports_path(**opts)
      url_params = { upload_id: @upload.id }
      url_params[:list_frame] = @list_turbo_frame if @list_turbo_frame.present? && @list_turbo_frame != "_top"
      Rowdy::Engine.routes.url_helpers.imports_path(**url_params.merge(opts))
    end

    def importable?
      @upload.completed? && @upload.schema_name.present?
    end

    def steps_frame_id
      "rowdy-steps-#{@upload.schema_name}"
    end

    def list_turbo_frame
      @list_turbo_frame || "rowdy-container"
    end

    def create_import_turbo_frame
      @create_turbo_frame || "rowdy-steps-#{@upload.schema_name}"
    end
  end
end
