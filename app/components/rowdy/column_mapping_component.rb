module Rowdy
  class ColumnMappingComponent < ViewComponent::Base
    def initialize(import:, detected_columns:, sample_rows:, schema_columns:, mapping: nil, errors: [])
      @import = import
      @detected_columns = detected_columns
      @sample_rows = sample_rows
      @schema_columns = schema_columns
      @mapping = mapping || import.column_mapping || {}
      @errors = errors
    end

    def save_mapping_path
      Rowdy::Engine.routes.url_helpers.save_mapping_import_path(@import)
    end

    def sample_values_for(column_index)
      @sample_rows.map { |row| row[column_index].truncate(20) }.compact.first(3)
    end

    def schema_options
      @schema_columns.map do |col|
        [ column_option_label(col), col.name.to_s ]
      end
    end

    def selected_mapping_for(uploaded_column)
      @mapping[uploaded_column] || auto_match(uploaded_column)
    end

    private

    def column_option_label(col)
      label = col.name.to_s.humanize
      label += " *" if col.required?
      label
    end

    def auto_match(uploaded_column)
      normalized = uploaded_column.to_s.strip.downcase.gsub(/[\s_-]+/, "_")

      match = @schema_columns.find do |col|
        col.name.to_s.downcase == normalized
      end

      match&.name&.to_s
    end
  end
end
