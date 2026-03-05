# frozen_string_literal: true

module Rowdy
  module ColumnValidators
    class RequiredValidator
      extend LightService::Action

      expects :value, :column, :errors

      executed do |ctx|
        next ctx unless ctx.column.required?
        next ctx unless blank?(ctx.value)

        ctx.errors << I18n.t("rowdy.column_validators.required")
      end

      def self.blank?(value)
        value.nil? || (value.is_a?(String) && value.strip.empty?)
      end
    end
  end
end
