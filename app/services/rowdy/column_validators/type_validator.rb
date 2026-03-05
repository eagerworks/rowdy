# frozen_string_literal: true

module Rowdy
  module ColumnValidators
    class TypeValidator
      extend LightService::Action

      expects :value, :column, :errors
      promises :coerced_value

      executed do |ctx|
        unless TypeCoercer.coercible?(ctx.value, ctx.column.type)
          ctx.errors << "must be a valid #{ctx.column.type}"
          ctx.coerced_value = nil
          next ctx
        end

        ctx.coerced_value = TypeCoercer.call(ctx.value, ctx.column.type)
      end
    end
  end
end
