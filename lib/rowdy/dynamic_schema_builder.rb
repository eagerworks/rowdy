module Rowdy
  module DynamicSchemaBuilder
    COLUMN_OPTIONS = %i[required unique max_length inclusion greater_than default].freeze

    class << self
      def build(schema_definition)
        klass = Class.new(Schema)

        sd_name  = schema_definition.name.to_s
        sd_label = schema_definition.label.to_s
        sd_id    = schema_definition.id

        klass.define_singleton_method(:schema_name) { sd_name }
        klass.define_singleton_method(:schema_label) { sd_label }
        klass.define_singleton_method(:dynamic?) { true }
        klass.define_singleton_method(:schema_definition_id) { sd_id }

        build_columns(klass, schema_definition.columns_config)

        klass
      end

      def all
        cache_valid? ? @cached_schemas : reload_all
      end

      def clear_cache
        @cached_schemas = nil
        @cache_key = nil
      end

      private

      def build_columns(klass, columns_config)
        columns_config.each do |col_hash|
          col = col_hash.symbolize_keys
          options = col.slice(*COLUMN_OPTIONS).compact

          options[:inclusion] = Array(options[:inclusion]) if options[:inclusion]
          options[:required]  = ActiveModel::Type::Boolean.new.cast(options[:required]) if options.key?(:required)
          options[:unique]    = ActiveModel::Type::Boolean.new.cast(options[:unique]) if options.key?(:unique)

          klass.column(col[:name].to_sym, type: col[:type].to_sym, **options)
        end
      end

      def reload_all
        definitions = SchemaDefinition.all.to_a
        @cache_key = compute_cache_key(definitions)
        @cached_schemas = definitions.map { |sd| build(sd) }
      end

      def cache_valid?
        return false if @cached_schemas.nil? || @cache_key.nil?

        current_key = compute_cache_key(SchemaDefinition.all.to_a)
        @cache_key == current_key
      end

      def compute_cache_key(definitions)
        definitions.map { |d| "#{d.id}-#{d.updated_at.to_f}" }.join("/")
      end
    end
  end
end
