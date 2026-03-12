module Rowdy
  class FindReplaceComponent < ViewComponent::Base
    attr_accessor :import, :tabs

    def initialize(import:, tabs: [])
      @import          = import
      @tabs = tabs
    end

    def replace_all_path
      Rowdy::Engine.routes.url_helpers.replace_all_import_path(@import)
    end

    def frame_id
      @import.steps_frame_id
    end
  end
end
