# frozen_string_literal: true

module Rowdy
  module ColumnValidators
    class InclusionValidator
      extend LightService::Action

      expects :value, :column, :errors

      executed do |ctx|
        next ctx unless ctx.column.inclusion.present?
        next ctx if ctx.column.inclusion.include?(ctx.value.to_s)

        ctx.errors << "must be one of: #{ctx.column.inclusion.join(', ')}"
      end
    end
  end
end
