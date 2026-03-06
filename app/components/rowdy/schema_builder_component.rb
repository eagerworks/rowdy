module Rowdy
  class SchemaBuilderComponent < ViewComponent::Base
    def endpoint_url
      Rowdy::Engine.routes.url_helpers.schema_definitions_path
    end
  end
end
