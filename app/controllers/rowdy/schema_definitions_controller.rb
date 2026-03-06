module Rowdy
  class SchemaDefinitionsController < ApplicationController
    before_action :set_schema_definition, only: %i[show update destroy]

    def index
      schema_definitions = SchemaDefinition.order(:name)

      render json: schema_definitions.map { |schema_definition| serialize(schema_definition) }
    end

    def show
      render json: serialize(@schema_definition)
    end

    def create
      @schema_definition = SchemaDefinition.new(schema_definition_params)

      if @schema_definition.save
        redirect_back_or_to '/'
      else
        render turbo_stream: turbo_stream.update(
          'schema-builder-errors',
          html: error_messages_html
        ), status: :unprocessable_entity
      end
    end

    def update
      if @schema_definition.update(schema_definition_params)
        render json: serialize(@schema_definition)
      else
        render json: { errors: @schema_definition.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @schema_definition.destroy!
      head :no_content
    end

    private

    def set_schema_definition
      @schema_definition = SchemaDefinition.find(params[:id])
    end

    def schema_definition_params
      permitted = params.require(:schema_definition).permit(:name, :label)
      permitted[:columns_config] = extract_columns_config
      permitted
    end

    def extract_columns_config
      raw = params.dig(:schema_definition, :columns_config)
      return [] if raw.blank?

      columns = if raw.is_a?(Array)
                  raw
                else
                  raw.keys.sort_by(&:to_i).map { |k| raw[k] }
                end

      columns.filter_map { |col| build_column_hash(col) }
    end

    def build_column_hash(col)
      permitted = col.permit(:name, :type, :required, :unique, :max_length, :greater_than, :inclusion)
      result = {}

      result['name'] = permitted[:name] if permitted[:name].present?
      result['type'] = permitted[:type] if permitted[:type].present?
      result['required'] = true if ActiveModel::Type::Boolean.new.cast(permitted[:required])
      result['unique'] = true if ActiveModel::Type::Boolean.new.cast(permitted[:unique])
      result['max_length'] = permitted[:max_length].to_i if permitted[:max_length].present?
      result['greater_than'] = permitted[:greater_than].to_f if permitted[:greater_than].present?

      if permitted[:inclusion].present?
        result['inclusion'] = permitted[:inclusion].split(',').map(&:strip).reject(&:blank?)
      end

      result
    end

    def error_messages_html
      helpers.safe_join(
        @schema_definition.errors.full_messages.map do |msg|
          helpers.content_tag(:p, msg, class: 'rowdy-schema-error-msg')
        end
      )
    end

    def serialize(schema_definition)
      {
        id: schema_definition.id,
        name: schema_definition.name,
        label: schema_definition.label,
        columns_config: schema_definition.columns_config,
        created_at: schema_definition.created_at,
        updated_at: schema_definition.updated_at
      }
    end
  end
end
