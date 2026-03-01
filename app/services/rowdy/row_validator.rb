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
      blank = value.nil? || (value.is_a?(String) && value.strip.empty?)

      if col.required? && blank
        errors << "is required"
        return errors
      end

      return errors if blank

      unless TypeCoercer.coercible?(value, col.type)
        errors << "must be a valid #{col.type}"
        return errors
      end

      coerced = TypeCoercer.call(value, col.type)

      if col.max_length && coerced.is_a?(String) && coerced.length > col.max_length
        errors << "must be at most #{col.max_length} characters"
      end

      if col.inclusion && !col.inclusion.include?(coerced.to_s)
        errors << "must be one of: #{col.inclusion.join(', ')}"
      end

      if col.greater_than && coerced.is_a?(Numeric) && coerced <= col.greater_than
        errors << "must be greater than #{col.greater_than}"
      end

      if col.unique? && unique_tracker
        unless unique_tracker.add?(col.name, coerced)
          errors << "must be unique"
        end
      end

      col.custom_validations.each do |validation|
        validation.call(coerced, errors)
      end

      errors
    end

    private_class_method :validate_column
  end
end
