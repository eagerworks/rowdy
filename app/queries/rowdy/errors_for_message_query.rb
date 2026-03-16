module Rowdy
  class ErrorsForMessageQuery
    def self.call(...) = new(...).call

    def initialize(import, message, page:, per_page:)
      @import   = import
      @message  = message
      @page     = page
      @per_page = per_page
    end

    def call
      @import.import_rows.active
        .where(*JsonQueryHelpers.any_array_value_condition(:column_errors, @message))
        .order(:row_number)
        .offset((@page - 1) * @per_page)
        .limit(@per_page)
    end
  end
end
