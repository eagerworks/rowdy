module Rowdy
  class RowTransformer
    def self.call(row, schema, column_mapping: {})
      transformed = {}
      schema_to_sheets = column_mapping.group_by { |_, v| v }.transform_values { |pairs| pairs.map(&:first) }

      schema.columns.each do |col|
        sheet_cols = schema_to_sheets[col.name.to_s] || []

        sheet_cols.each do |sheet_col|
          value = row[sheet_col]

          value = col.default if value.nil? || (value.is_a?(String) && value.strip.empty?)

          col.custom_transformations.each { |transform| value = transform.call(value) }

          coerced = TypeCoercer.call(value, col.type)
          transformed[sheet_col] = coerced.nil? ? value : coerced
        end
      end

      mapped_sheet_cols = column_mapping.keys
      row.each do |col, value|
        next if mapped_sheet_cols.include?(col.to_s)

        transformed[col] = value
      end

      transformed
    end
  end
end
