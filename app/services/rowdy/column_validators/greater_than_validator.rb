# frozen_string_literal: true

module Rowdy
  module ColumnValidators
    class GreaterThanValidator < BaseValidator
      def call
        return unless column.greater_than.present?
        return unless value.is_a?(Numeric) && value <= column.greater_than

        errors << "must be greater than #{column.greater_than}"
      end
    end
  end
end
