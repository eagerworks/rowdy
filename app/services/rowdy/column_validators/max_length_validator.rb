# frozen_string_literal: true

module Rowdy
  module ColumnValidators
    class MaxLengthValidator
      extend LightService::Action

      expects :value, :column, :errors

      executed do |ctx|
        next ctx unless ctx.column.max_length.present?
        next ctx unless ctx.value.is_a?(String) && ctx.value.length > ctx.column.max_length

        ctx.errors << I18n.t("rowdy.column_validators.max_length", max: ctx.column.max_length)
      end
    end
  end
end
