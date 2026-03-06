module Rowdy
  module SchemaRegistry
    class << self
      def all
        static_schemas + dynamic_schemas
      end

      def static_schemas
        Rowdy.configuration.schemas
      end

      def dynamic_schemas
        DynamicSchemaBuilder.all
      rescue ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError
        []
      end

      def find(schema_name)
        all.find { |s| s.schema_name == schema_name.to_s }
      end

      def find!(schema_name)
        find(schema_name) || raise(ArgumentError, "Schema '#{schema_name}' not found")
      end
    end
  end
end
