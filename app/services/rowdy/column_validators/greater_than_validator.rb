# frozen_string_literal: true

module Rowdy
  module ColumnValidators
    class GreaterThanValidator
      extend LightService::Action

      expects :value, :column, :errors

      executed do |ctx|
        next ctx unless ctx.column.greater_than.present?
        next ctx unless ctx.value.is_a?(Numeric) && ctx.value <= ctx.column.greater_than

        ctx.errors << "must be greater than #{ctx.column.greater_than}"
      end
    end
  end
end
