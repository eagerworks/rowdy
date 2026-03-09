# frozen_string_literal: true

module Rowdy
  module ColumnValidators
    class ColumnValidationPipeline
      extend LightService::Organizer

      def self.call(value:, column:, errors:, unique_tracker:, import_row: nil)
        with(value: value, column: column, errors: errors, unique_tracker: unique_tracker, import_row: import_row).reduce(
          MaxLengthValidator,
          InclusionValidator,
          GreaterThanValidator,
          UniqueValidator,
          CustomValidator
        )
      end
    end
  end
end
