module Rowdy
  class SchemaBuilderComponent < ViewComponent::Base
    def initialize(schema_definition: nil)
      @schema_definition = schema_definition
    end

    def edit_mode?
      @schema_definition.present?
    end

    def endpoint_url
      if edit_mode?
        Rowdy::Engine.routes.url_helpers.schema_definition_path(@schema_definition)
      else
        Rowdy::Engine.routes.url_helpers.schema_definitions_path
      end
    end

    def http_method
      edit_mode? ? :patch : :post
    end

    def existing_columns
      return [] unless edit_mode?
      @schema_definition.columns_config || []
    end

    def initial_column_index
      existing_columns.size
    end

    def inclusion_string(col)
      col["inclusion"]&.join(", ") || ""
    end

    def field_style(col, *types)
      "display: none;" unless types.include?(col["type"])
    end
  end
end
