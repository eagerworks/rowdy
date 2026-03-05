# frozen_string_literal: true

module Rowdy
  module ColumnValidators
    class UniqueValidator
      extend LightService::Action

      expects :value, :column, :errors, :unique_tracker

      executed do |ctx|
        next ctx unless ctx.column.unique?
        next ctx unless ctx.unique_tracker

        ctx.errors << "must be unique" unless ctx.unique_tracker.add?(ctx.column.name, ctx.value)
      end
    end
  end
end
