module Rowdy
  class ValidationResultComponent < ViewComponent::Base
    attr_accessor :import, :errors, :page, :total_pages, :errored_columns, :tab, :error_types_with_counts

    def initialize(import:, errors: [], page: 1, total_pages: 0, errored_columns: [], tab: 0, error_types_with_counts: [])
      @import                   = import
      @errors                   = errors
      @page                     = page
      @total_pages              = total_pages
      @errored_columns          = errored_columns
      @tab                      = tab
      @error_types_with_counts  = error_types_with_counts
    end

    def preparing?
      @import.preparing?
    end

    def validating?
      @import.validating?
    end

    def in_progress?
      preparing? || validating?
    end

    def validated?
      @import.validated?
    end

    def has_errors?
      @import.invalid_rows_count.positive?
    end

    def has_valid_rows?
      @import.valid_rows_count.positive?
    end

    def mapping_path
      Rowdy::Engine.routes.url_helpers.import_mapping_path(@import)
    end

    def validation_path(page: 1, tab: @tab)
      Rowdy::Engine.routes.url_helpers.import_validation_path(@import, page: page, tab: tab)
    end

    def error_report_path
      Rowdy::Engine.routes.url_helpers.error_report_import_path(@import)
    end

    def start_validation_path
      Rowdy::Engine.routes.url_helpers.import_validation_path(@import)
    end

    def correct_errors_path
      Rowdy::Engine.routes.url_helpers.correct_errors_import_path(@import)
    end

    def frame_id
      @import.steps_frame_id
    end

    def previous_page?
      @page > 1
    end

    def next_page?
      @page < @total_pages
    end

    def error_types
      @error_types_with_counts.map(&:first)
    end

    def row_count_for_error_type(column)
      @error_types_with_counts.find { |col, _| col == column }&.last || 0
    end

    def label_for_error_type(column)
      column.to_s
    end

    def entries_for_error_type(message)
      @errors.flat_map do |import_error|
        (import_error.column_errors || {}).filter_map do |column, msgs|
          next unless Array(msgs).include?(message)

          { import_error: import_error, column: column, messages: [ message ] }
        end
      end
    end
  end
end
