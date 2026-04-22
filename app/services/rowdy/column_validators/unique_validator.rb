# frozen_string_literal: true

module Rowdy
  module ColumnValidators
    class UniqueValidator
      extend LightService::Action

      expects :value, :column, :errors, :unique_tracker
      expects :import_row, :sheet_column

      executed do |ctx|
        next ctx unless ctx.column.unique?

        duplicate =
          if ctx.unique_tracker
            !ctx.unique_tracker.add?(ctx.column.name, ctx.value)
          else
            next ctx unless ctx.import_row
            duplicate_exists?(ctx.import_row, ctx.sheet_column || ctx.column.name, ctx.value.to_s)
          end

        ctx.errors << I18n.t("rowdy.column_validators.unique") if duplicate
      end

      def self.duplicate_exists?(import_row, column_name, value)
        extract_sql = JsonQueryHelpers.extract("row_data", column_name)

        ImportRow.where(import_id: import_row.import_id)
         .where.not(id: import_row.id)
         .where(corrected_at: nil)
         .where("#{extract_sql} = ?", value)
         .exists?
      end
      private_class_method :duplicate_exists?
    end
  end
end
