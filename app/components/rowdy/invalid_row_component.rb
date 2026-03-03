module Rowdy
  class InvalidRowComponent < ViewComponent::Base
    def initialize(import_error:, column:, messages:)
      @import_error = import_error
      @column = column
      @messages = messages
    end

    def current_value
      @import_error.row_data[@column].to_s
    end

    def input_name
      "corrections[#{@import_error.id}][#{@column}]"
    end
  end
end
