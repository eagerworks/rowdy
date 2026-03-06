module Rowdy
  class SchemasComponent < ViewComponent::Base
    def initialize
      @schemas = SchemaRegistry.all
      @upload_counts = Upload.group(:schema_name).count
    end

    def schema_path(schema)
      Rowdy::Engine.routes.url_helpers.schema_path(schema_name: schema.schema_name)
    end

    def upload_count(schema)
      @upload_counts[schema.schema_name] || 0
    end
  end
end
