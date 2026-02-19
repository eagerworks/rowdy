module Rowdy
  class Schema
    class << self
      def schema_name
        name.demodulize.underscore.sub(/_schema$/, "")
      end

      def schema_label
        schema_name.humanize
      end

      def columns
        @columns ||= []
      end

      def column(name, type:, **options, &block)
        col = ColumnDefinition.new(name: name, type: type, **options)
        col.instance_eval(&block) if block_given?
        columns << col
      end

      def column_names
        columns.map(&:name)
      end

      def required_columns
        columns.select(&:required?)
      end

      def find_column(name)
        columns.find { |c| c.name == name.to_sym }
      end
    end
  end
end
