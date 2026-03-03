# frozen_string_literal: true

module Rowdy
  module ColumnValidators
    class BaseValidator
      def initialize(value:, column:, errors:, unique_tracker: nil, **options)
        @value = value
        @column = column
        @errors = errors
        @unique_tracker = unique_tracker
        @options = options
      end

      def call
        raise NotImplementedError, "#{self.class}#call must be implemented"
      end

      private

      attr_reader :value, :column, :errors, :unique_tracker, :options
    end
  end
end
