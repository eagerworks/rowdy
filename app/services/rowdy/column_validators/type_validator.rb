# frozen_string_literal: true

module Rowdy
  module ColumnValidators
    class TypeValidator
      def self.call(value, column, errors)
        unless TypeCoercer.coercible?(value, column.type)
          errors << "must be a valid #{column.type}"
          return nil
        end

        TypeCoercer.call(value, column.type)
      end
    end
  end
end
