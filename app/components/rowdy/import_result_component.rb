module Rowdy
  class ImportResultComponent < ViewComponent::Base
    def initialize(import:)
      @import = import
    end
  end
end
