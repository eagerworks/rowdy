module Rowdy
  class ValidationResultComponent < ViewComponent::Base
    attr_accessor :import, :errors, :page, :total_pages, :errored_columns

    def initialize(import:, errors: [], page: 1, total_pages: 0, errored_columns: [])
      @import          = import
      @errors          = errors
      @page            = page
      @total_pages     = total_pages
      @errored_columns = errored_columns
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
      Rowdy::Engine.routes.url_helpers.mapping_import_path(@import)
    end

    def validation_path(page: 1)
      Rowdy::Engine.routes.url_helpers.validation_import_path(@import, page: page)
    end

    def error_report_path
      Rowdy::Engine.routes.url_helpers.error_report_import_path(@import)
    end

    def start_validation_path
      Rowdy::Engine.routes.url_helpers.validate_import_path(@import)
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

    # Error type categories in display order. Used to group validation messages into tabs.
    ERROR_TYPE_ORDER = %i[presence type length inclusion numeric uniqueness custom].freeze

    # Classifies a validation message into a category key for tab grouping.
    def self.classify_error_message(message)
      msg = message.to_s
      return :presence if msg == "is required"
      return :uniqueness if msg == "must be unique"
      return :type if msg.start_with?("must be a valid ")
      return :length if msg.start_with?("must be at most ")
      return :inclusion if msg.start_with?("must be one of:")
      return :numeric if msg.start_with?("must be greater than ")
      :custom
    end

    # Unique error type categories present on the current page, in ERROR_TYPE_ORDER.
    def error_types
      @error_types ||= begin
        categories = Set.new
        @errors.each do |import_error|
          (import_error.column_errors || {}).each_value do |msgs|
            Array(msgs).each { |msg| categories.add(self.class.classify_error_message(msg)) }
          end
        end
        ERROR_TYPE_ORDER.select { |c| categories.include?(c) }
      end
    end

    # Number of distinct rows (import_errors) that have at least one error of this type.
    # Capped at the page size — a row is counted once regardless of how many columns are affected.
    def row_count_for_error_type(category)
      @errors.count do |import_error|
        (import_error.column_errors || {}).any? do |_, msgs|
          Array(msgs).any? { |msg| self.class.classify_error_message(msg) == category }
        end
      end
    end

    def label_for_error_type(category)
      I18n.t("rowdy.import.validation.error_type_#{category}")
    end

    # For a given error type category, returns an array of hashes:
    # { import_error:, column:, messages: [msg, ...] } with only messages that match the category.
    def entries_for_error_type(category)
      entries = []
      @errors.each do |import_error|
        (import_error.column_errors || {}).each do |column, msgs|
          matching = Array(msgs).select { |msg| self.class.classify_error_message(msg) == category }
          next if matching.empty?

          entries << { import_error: import_error, column: column, messages: matching }
        end
      end
      entries
    end
  end
end
