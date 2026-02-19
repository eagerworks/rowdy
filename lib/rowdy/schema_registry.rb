module Rowdy
  module SchemaRegistry
    class << self
      def all
        Rowdy.configuration.schemas
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
