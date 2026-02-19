module Rowdy
  class TypeCoercer
    COERCIONS = {
      string: ->(val) { val.to_s },
      integer: ->(val) { Integer(val) },
      float: ->(val) { Float(val) },
      decimal: ->(val) { BigDecimal(val.to_s) },
      boolean: ->(val) { coerce_boolean(val) },
      date: ->(val) { coerce_date(val) }
    }.freeze

    def self.call(value, type)
      return nil if value.nil? || (value.is_a?(String) && value.strip.empty?)

      coercion = COERCIONS.fetch(type) { raise ArgumentError, "Unknown type: #{type}" }
      coercion.call(value)
    rescue ArgumentError, TypeError
      nil
    end

    def self.coercible?(value, type)
      return true if value.nil? || (value.is_a?(String) && value.strip.empty?)

      call(value, type) != nil
    end

    def self.coerce_boolean(val)
      case val.to_s.strip.downcase
      when "true", "1", "yes", "si", "sí" then true
      when "false", "0", "no" then false
      else raise ArgumentError, "Cannot coerce to boolean: #{val}"
      end
    end

    def self.coerce_date(val)
      return val if val.is_a?(Date) || val.is_a?(Time) || val.is_a?(DateTime)

      Date.parse(val.to_s)
    end

    private_class_method :coerce_boolean, :coerce_date
  end
end
