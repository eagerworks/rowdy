# frozen_string_literal: true

module Rowdy
  module ColumnValidators
    class UniqueValidator
      extend LightService::Action

      expects :value, :column, :errors, :unique_tracker
      expects :import_row

      executed do |ctx|
        next ctx unless ctx.column.unique?

        duplicate =
          if ctx.unique_tracker
            !ctx.unique_tracker.add?(ctx.column.name, ctx.value)
          else
            next ctx unless ctx.import_row
            duplicate_exists?(ctx.import_row, ctx.column.name, ctx.value.to_s)
          end

        ctx.errors << I18n.t("rowdy.column_validators.unique") if duplicate
      end

      def self.duplicate_exists?(import_row, column_name, value)
        extract_sql = JsonQueryHelpers.extract("row_data", column_name)
        sql = ActiveRecord::Base.sanitize_sql_array([
          "SELECT EXISTS(SELECT 1 FROM rowdy_import_rows WHERE import_id = ? AND id != ? AND #{extract_sql} = ?)",
          import_row.import_id,
          import_row.id,
          value
        ])
        result = ActiveRecord::Base.connection.select_value(sql)
        result == true || result == "t" || result == 1
      end
      private_class_method :duplicate_exists?
    end
  end
end
