# frozen_string_literal: true

module Rowdy
  module ColumnValidators
    class InclusionValidator
      extend LightService::Action

      expects :value, :column, :errors

      executed do |ctx|
        next ctx unless ctx.column.inclusion.present?
        next ctx if ctx.column.inclusion.include?(ctx.value.to_s)

        ctx.errors << I18n.t("rowdy.column_validators.inclusion", values: ctx.column.inclusion.join(", "))
      end
    end
  end
end
