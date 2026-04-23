# frozen_string_literal: true

module Rowdy
  module ColumnValidators
    class ColumnValidationPipeline
      extend LightService::Organizer

      def self.call(value:, column:, errors:, unique_tracker:, import_row: nil, sheet_column: nil)
        with(value:, column:, errors:, unique_tracker:, import_row:, sheet_column:).reduce(
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
