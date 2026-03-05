module Rowdy
  class FindReplaceComponent < ViewComponent::Base
    def initialize(import:, errored_columns: [])
      @import          = import
      @errored_columns = errored_columns
    end

    def replace_all_path
      Rowdy::Engine.routes.url_helpers.replace_all_import_path(@import)
    end

    def frame_id
      @import.steps_frame_id
    end
  end
end
