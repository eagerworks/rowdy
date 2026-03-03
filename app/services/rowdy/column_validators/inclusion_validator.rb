# frozen_string_literal: true

module Rowdy
  module ColumnValidators
    class InclusionValidator < BaseValidator
      def call
        return unless column.inclusion.present?
        return if column.inclusion.include?(value.to_s)

        errors << "must be one of: #{column.inclusion.join(', ')}"
      end
    end
  end
end
