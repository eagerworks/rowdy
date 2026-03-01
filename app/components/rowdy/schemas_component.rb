module Rowdy
  class SchemasComponent < ViewComponent::Base
    def initialize
      @schemas = SchemaRegistry.all
    end
  end
end
