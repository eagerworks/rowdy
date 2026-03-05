module Rowdy
  module JsonQueryHelpers
    SUPPORTED_ADAPTERS = %w[PostgreSQL Mysql2 Trilogy].freeze

    # WHERE condition for key existence in a JSON column.
    # Returns a [sql, *binds] array suitable for .where(*condition).
    def self.has_key_condition(column, key)
      validate_adapter!
      safe_key = sanitize_key(key)
      case adapter_name
      when "PostgreSQL"
        [ "jsonb_exists(#{column}, ?)", key ]
      when "Mysql2", "Trilogy"
        [ "JSON_CONTAINS_PATH(#{column}, 'one', '$.#{safe_key}')" ]
      end
    end

    # WHERE condition: JSON field value is blank.
    def self.empty_condition(column, key)
      col = extract(column, key)
      [ "TRIM(COALESCE(#{col}, '')) = ''" ]
    end

    # WHERE condition: JSON field value exactly matches.
    def self.exact_condition(column, key, value, case_sensitive: true)
      col = extract(column, key)
      if case_sensitive
        case adapter_name
        when "PostgreSQL"        then [ "#{col} = ?", value ]
        when "Mysql2", "Trilogy" then [ "#{col} = ? COLLATE utf8mb4_bin", value ]
        end
      else
        [ "LOWER(#{col}) = LOWER(?)", value ]
      end
    end

    # WHERE condition: JSON field value contains substring.
    def self.contains_condition(column, key, value, case_sensitive: true)
      col = extract(column, key)
      escaped = ActiveRecord::Base.sanitize_sql_like(value)
      if case_sensitive
        case adapter_name
        when "PostgreSQL"        then [ "#{col} LIKE ?", "%#{escaped}%" ]
        when "Mysql2", "Trilogy" then [ "#{col} LIKE ? COLLATE utf8mb4_bin", "%#{escaped}%" ]
        end
      else
        [ "LOWER(#{col}) LIKE LOWER(?)", "%#{escaped}%" ]
      end
    end

    # SET clause for update_all: sets one JSON field to a scalar value.
    # Returns a [sql_fragment, *binds] array.
    # Usage: sql, *binds = json_set_sql("row_data", "category", "other")
    #        Model.where(...).update_all(["corrected_at = ?, #{sql}", Time.current, *binds])
    def self.json_set_sql(column, key, value)
      validate_adapter!
      safe_key = sanitize_key(key)
      case adapter_name
      when "PostgreSQL"
        [ "#{column} = jsonb_set(#{column}, ?, ?::jsonb)", "{#{safe_key}}", value.to_json ]
      when "Mysql2", "Trilogy"
        [ "#{column} = JSON_SET(#{column}, '$.#{safe_key}', ?)", value ]
      end
    end

    # SQL fragment for extracting a JSON field as text.
    # Used internally and by callers that need raw SQL.
    def self.extract(column, key)
      validate_adapter!
      safe_key = sanitize_key(key)
      case adapter_name
      when "PostgreSQL"        then "#{column}->>'#{safe_key}'"
      when "Mysql2", "Trilogy" then "JSON_UNQUOTE(JSON_EXTRACT(#{column}, '$.#{safe_key}'))"
      end
    end

    def self.adapter_name
      ActiveRecord::Base.connection.adapter_name
    end

    class UnsupportedAdapterError < StandardError; end

    private_class_method def self.validate_adapter!
      return if SUPPORTED_ADAPTERS.include?(adapter_name)
      raise UnsupportedAdapterError,
            "Unsupported database adapter: #{adapter_name}. Rowdy requires PostgreSQL or MySQL."
    end

    private_class_method def self.sanitize_key(key)
      key.to_s.gsub(/[^a-zA-Z0-9_]/, "")
    end
  end
end
