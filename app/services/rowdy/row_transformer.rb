module Rowdy
  class RowTransformer
    def self.call(row, schema)
      transformed = {}

      schema.columns.each do |col|
        value = row[col.name]

        value = col.default if value.nil? || (value.is_a?(String) && value.strip.empty?)

        col.custom_transformations.each do |transform|
          value = transform.call(value)
        end

        coerced = TypeCoercer.call(value, col.type)
        transformed[col.name] = coerced.nil? ? value : coerced
      end

      transformed
    end
  end
end
