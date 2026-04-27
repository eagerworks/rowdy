module Rowdy
  class ColumnMappingComponent < ViewComponent::Base
    attr_accessor :import, :detected_columns, :sample_rows, :schema_columns, :frame_id, :mapping, :errors

    def initialize(import:, detected_columns:, sample_rows:, schema_columns:, frame_id:, mapping: nil, errors: [])
      @import = import
      @detected_columns = detected_columns
      @sample_rows = sample_rows
      @schema_columns = schema_columns
      @mapping = mapping || import.column_mapping || {}
      @errors = errors
      @frame_id = frame_id
    end

    def mapping_path
      Rowdy::Engine.routes.url_helpers.import_mapping_path(@import)
    end

    def schema_path
      Rowdy::Engine.routes.url_helpers.schema_path(schema_name: @import.schema_name, frame_id: turbo_frame_id)
    end

    def sample_values_for(column_index)
      @sample_rows.map { |row| row[column_index]&.truncate(20) }.compact.first(3)
    end

    def schema_options
      @schema_columns.map do |col|
        [ column_option_label(col), col.name.to_s ]
      end
    end

    def turbo_frame_id
      frame_id || @import.steps_frame_id
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
