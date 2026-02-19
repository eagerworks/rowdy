module Rowdy
  class SchemasComponent < ViewComponent::Base
    def initialize
      @schemas = SchemaRegistry.all
    end

    def uploads_for(schema)
      Upload.where(schema_name: schema.schema_name).order(created_at: :desc)
    end
  end
end
