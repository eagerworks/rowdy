# frozen_string_literal: true

module Rowdy
  class RowValidator
    def self.call(row, schema, unique_tracker: nil, import_row: nil)
      errors = {}

      schema.columns.each do |col|
        value = row[col.name]
        col_errors = validate_column(value, col, unique_tracker, import_row)
        errors[col.name.to_s] = col_errors if col_errors.any?
      end

      errors
    end

    def self.validate_column(value, col, unique_tracker, import_row)
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
        errors: errors,
        unique_tracker: unique_tracker,
        import_row: import_row
      )

      errors
    end

    private_class_method :validate_column
  end
end
