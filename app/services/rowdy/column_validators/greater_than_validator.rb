# frozen_string_literal: true

module Rowdy
  module ColumnValidators
    class GreaterThanValidator
      extend LightService::Action

      expects :value, :column, :errors

      executed do |ctx|
        next ctx unless ctx.column.greater_than.present?
        next ctx unless ctx.value.is_a?(Numeric) && ctx.value <= ctx.column.greater_than

        ctx.errors << I18n.t("rowdy.column_validators.greater_than", threshold: ctx.column.greater_than)
      end
    end
  end
end
