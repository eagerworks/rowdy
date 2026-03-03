# frozen_string_literal: true

module Rowdy
  module ColumnValidators
    class UniqueValidator < BaseValidator
      def call
        return unless column.unique?
        return unless unique_tracker

        errors << "must be unique" unless unique_tracker.add?(column.name, value)
      end
    end
  end
end
