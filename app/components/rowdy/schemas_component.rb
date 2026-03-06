module Rowdy
  class SchemasComponent < ViewComponent::Base
    def initialize
      @schemas = SchemaRegistry.all
    end

    def schema_path(schema)
      Rowdy::Engine.routes.url_helpers.schema_path(schema_name: schema.schema_name)
    end

    def upload_count(schema)
      Upload.where(schema_name: schema.schema_name).count
    end
  end
end
