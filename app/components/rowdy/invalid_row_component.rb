module Rowdy
  class InvalidRowComponent < ViewComponent::Base
    attr_reader :import_row, :column, :messages

    def initialize(import_row:, column:, messages:)
      @import_row = import_row
      @column = column
      @messages = messages
    end

    def current_value
      @import_row.row_data[@column].to_s
    end

    def input_name
      "corrections[#{@import_row.id}][#{@column}]"
    end
  end
end
