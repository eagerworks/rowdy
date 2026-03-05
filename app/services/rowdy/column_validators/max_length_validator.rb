# frozen_string_literal: true

module Rowdy
  module ColumnValidators
    class MaxLengthValidator
      extend LightService::Action

      expects :value, :column, :errors

      executed do |ctx|
        next ctx unless ctx.column.max_length.present?
        next ctx unless ctx.value.is_a?(String) && ctx.value.length > ctx.column.max_length

        ctx.errors << "must be at most #{ctx.column.max_length} characters"
      end
    end
  end
end
