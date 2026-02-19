module Rowdy
  class ColumnDefinition
    attr_reader :name, :type, :required, :unique, :max_length,
                :inclusion, :greater_than, :default,
                :custom_validations, :custom_transformations

    VALID_TYPES = %i[string integer float decimal date boolean].freeze

    def initialize(name:, type:, required: false, unique: false, max_length: nil,
                   inclusion: nil, greater_than: nil, default: nil)
      raise ArgumentError, "Invalid type: #{type}" unless VALID_TYPES.include?(type)

      @name = name.to_sym
      @type = type
      @required = required
      @unique = unique
      @max_length = max_length
      @inclusion = inclusion
      @greater_than = greater_than
      @default = default
      @custom_validations = []
      @custom_transformations = []
    end

    def validate(&block)
      @custom_validations << block
    end

    def transform(&block)
      @custom_transformations << block
    end

    def required?
      @required
    end

    def unique?
      @unique
    end
  end
end
