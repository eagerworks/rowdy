# frozen_string_literal: true

module Rowdy
  class RowValidator
    def self.call(row, schema, unique_tracker: nil, import_row: nil, column_mapping: {})
      errors = {}
      schema_to_sheets = column_mapping.group_by { |_, v| v }.transform_values { |pairs| pairs.map(&:first) }

      schema.columns.each do |col|
        sheet_cols = schema_to_sheets[col.name.to_s]

        if sheet_cols.blank?
          col_errors = validate_column(nil, col, unique_tracker, import_row, nil)
          errors[col.name.to_s] = col_errors if col_errors.any?
        else
          sheet_cols.each do |sheet_col|
            value = row[sheet_col]
            col_errors = validate_column(value, col, unique_tracker, import_row, sheet_col)
            errors[sheet_col] = col_errors if col_errors.any?
          end
        end
      end

      errors
    end

    def self.validate_column(value, col, unique_tracker, import_row, sheet_col)
      errors = []

      ColumnValidators::RequiredValidator.execute(value: value, column: col, errors: errors)
      return errors if errors.any?

      return errors if ColumnValidators::RequiredValidator.blank?(value)

      type_result = ColumnValidators::TypeValidator.execute(value: value, column: col, errors: errors)
      return errors if errors.any?
      return errors unless type_result.coerced_value

      ColumnValidators::ColumnValidationPipeline.call(
        value: type_result.coerced_value,
        column: col,
        errors:,
        unique_tracker:,
        import_row:,
        sheet_column: sheet_col
      )

      errors
    end

    private_class_method :validate_column
  end
end
