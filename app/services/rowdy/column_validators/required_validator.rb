# frozen_string_literal: true

module Rowdy
  module ColumnValidators
    class RequiredValidator
      def self.call(value, column, errors)
        return unless column.required?
        return unless blank?(value)

        errors << "is required"
      end

      def self.blank?(value)
        value.nil? || (value.is_a?(String) && value.strip.empty?)
      end
    end
  end
end
