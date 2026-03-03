# frozen_string_literal: true

module Rowdy
  class RowValidator
    def self.call(row, schema, unique_tracker: nil)
      errors = {}

      schema.columns.each do |col|
        value = row[col.name]
        col_errors = validate_column(value, col, unique_tracker)
        errors[col.name.to_s] = col_errors if col_errors.any?
      end

      errors
    end

    def self.validate_column(value, col, unique_tracker)
      errors = []

      ColumnValidators::RequiredValidator.call(value, col, errors)
      return errors if errors.any?

      return errors if ColumnValidators::RequiredValidator.blank?(value)

      coerced = ColumnValidators::TypeValidator.call(value, col, errors)
      return errors if errors.any?
      return errors unless coerced

      ColumnValidators::ColumnValidationPipeline.call(
        value: coerced,
        column: col,
        errors: errors,
        unique_tracker: unique_tracker
      )

      errors
    end

    private_class_method :validate_column
  end
end
