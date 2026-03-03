# frozen_string_literal: true

module Rowdy
  module ColumnValidators
    class MaxLengthValidator < BaseValidator
      def call
        return unless column.max_length.present?
        return unless value.is_a?(String) && value.length > column.max_length

        errors << "must be at most #{column.max_length} characters"
      end
    end
  end
end
