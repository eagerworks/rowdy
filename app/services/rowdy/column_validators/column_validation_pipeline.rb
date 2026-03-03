# frozen_string_literal: true

module Rowdy
  module ColumnValidators
    class ColumnValidationPipeline
      VALIDATORS = [
        MaxLengthValidator, InclusionValidator, GreaterThanValidator,
        UniqueValidator, CustomValidator
      ].freeze

      def self.call(value:, column:, errors:, unique_tracker:)
        VALIDATORS.map do |klass|
          klass.new(
            value:,
            column:,
            errors:,
            unique_tracker:
          ).call
        end
      end
    end
  end
end
