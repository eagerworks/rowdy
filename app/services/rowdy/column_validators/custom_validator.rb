# frozen_string_literal: true

module Rowdy
  module ColumnValidators
    class CustomValidator
      extend LightService::Action

      expects :value, :column, :errors

      executed do |ctx|
        next ctx unless ctx.column.custom_validations.any?

        ctx.column.custom_validations.each do |validation|
          validation.call(ctx.value, ctx.errors)
        end
      end
    end
  end
end
