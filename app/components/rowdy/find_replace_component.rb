module Rowdy
  class FindReplaceComponent < ViewComponent::Base
    attr_accessor :import

    def initialize(import:, tabs: nil, frame_id: nil)
      @import   = import
      @frame_id = frame_id
    end

    def replace_all_path
      Rowdy::Engine.routes.url_helpers.replace_all_import_path(@import)
    end

    def columns
      ErroredColumnsQuery.call(@import)
    end

    def frame_id
      @frame_id || @import.steps_frame_id
    end
  end
end
