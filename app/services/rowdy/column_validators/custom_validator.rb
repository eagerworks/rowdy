# frozen_string_literal: true

module Rowdy
  module ColumnValidators
    class CustomValidator < BaseValidator
      def call
        return unless column.custom_validations.any?

        column.custom_validations.each do |validation|
          validation.call(value, errors)
        end
      end
    end
  end
end
