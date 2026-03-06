module Rowdy
  class SchemaDefinition < ApplicationRecord
    serialize :columns_config, coder: JSON

    validates :name, presence: true,
                     uniqueness: true,
                     format: { with: /\A[a-z][a-z0-9_]*\z/, message: "must be lowercase snake_case" }
    validates :columns_config, presence: true
    validate :validate_columns_config
    validate :name_not_in_static_registry

    before_validation :derive_label

    after_commit :clear_dynamic_schema_cache

    def to_schema
      DynamicSchemaBuilder.build(self)
    end

    private

    def derive_label
      self.label = name.humanize if label.blank? && name.present?
    end

    def clear_dynamic_schema_cache
      DynamicSchemaBuilder.clear_cache
    end

    def name_not_in_static_registry
      return if name.blank?

      static_names = SchemaRegistry.static_schemas.map(&:schema_name)
      if static_names.include?(name)
        errors.add(:name, "is already used by a static schema")
      end
    end

    def validate_columns_config
      return if columns_config.blank?

      unless columns_config.is_a?(Array)
        errors.add(:columns_config, "must be an array of column definitions")
        return
      end

      if columns_config.empty?
        errors.add(:columns_config, "must have at least one column")
        return
      end

      seen_names = Set.new

      columns_config.each_with_index do |col, idx|
        validate_single_column(col, idx, seen_names)
      end
    end

    def validate_single_column(col, idx, seen_names)
      prefix = "columns_config[#{idx}]"

      unless col.is_a?(Hash)
        errors.add(:columns_config, "#{prefix} must be a hash")
        return
      end

      col = col.symbolize_keys

      if col[:name].blank?
        errors.add(:columns_config, "#{prefix} is missing 'name'")
      elsif seen_names.include?(col[:name].to_s)
        errors.add(:columns_config, "#{prefix} has duplicate name '#{col[:name]}'")
      else
        seen_names << col[:name].to_s
      end

      if col[:type].blank?
        errors.add(:columns_config, "#{prefix} is missing 'type'")
      elsif !ColumnDefinition::VALID_TYPES.include?(col[:type].to_sym)
        errors.add(:columns_config, "#{prefix} has invalid type '#{col[:type]}'. Valid types: #{ColumnDefinition::VALID_TYPES.join(', ')}")
      end
    end
  end
end
