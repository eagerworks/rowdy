module Rowdy
  class ValidationResultComponent < ViewComponent::Base
    def initialize(import:, errors: [], page: 1, total_pages: 0)
      @import = import
      @errors = errors
      @page = page
      @total_pages = total_pages
    end

    def validating?
      @import.validating?
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
      Rowdy::Engine.routes.url_helpers.mapping_import_path(@import)
    end

    def validation_path(page: 1)
      Rowdy::Engine.routes.url_helpers.validation_import_path(@import, page: page)
    end

    def error_report_path
      Rowdy::Engine.routes.url_helpers.error_report_import_path(@import)
    end

    def previous_page?
      @page > 1
    end

    def next_page?
      @page < @total_pages
    end
  end
end
