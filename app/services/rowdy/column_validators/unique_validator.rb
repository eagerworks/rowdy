# frozen_string_literal: true

module Rowdy
  module ColumnValidators
    class UniqueValidator
      extend LightService::Action

      expects :value, :column, :errors, :unique_tracker
      expects :import_row, :sheet_column, :corrections

      executed do |ctx|
        next ctx unless ctx.column.unique?

        duplicate =
          if ctx.unique_tracker
            !ctx.unique_tracker.add?(ctx.column.name, ctx.value)
          else
            next ctx unless ctx.import_row
            column_name = ctx.sheet_column || ctx.column.name
            duplicate_exists?(ctx.import_row, column_name, ctx.value.to_s, ctx.corrections)
          end

        ctx.errors << I18n.t("rowdy.column_validators.unique") if duplicate
      end

      def self.duplicate_exists?(import_row, column_name, value, corrections = {})
        return true if correction_duplicate?(import_row.id, column_name, value, corrections)

        extract_sql = JsonQueryHelpers.extract("row_data", column_name)

        ImportRow.where(import_id: import_row.import_id)
         .where.not(id: import_row.id)
         .where(corrected_at: nil)
         .where("#{extract_sql} = ?", value)
         .exists?
      end

      def self.correction_duplicate?(import_row_id, column_name, value, corrections)
        corrections.any? do |row_id, new_values|
          row_id.to_s != import_row_id.to_s && new_values[column_name].to_s == value
        end
      end

      private_class_method :duplicate_exists?, :correction_duplicate?
    end
  end
end
