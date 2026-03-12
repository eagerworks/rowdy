module Rowdy
  module JsonQueryHelpers
    SUPPORTED_ADAPTERS = %w[PostgreSQL Mysql2 Trilogy].freeze

    # WHERE condition for key existence in a JSON column.
    # Returns a [sql, *binds] array suitable for .where(*condition).
    def self.has_key_condition(column, key)
      safe_key = sanitize_key(key)

      if postgresql?
        [ "jsonb_exists(#{column}, ?)", key ]
      elsif mysql?
        [ "JSON_CONTAINS_PATH(#{column}, 'one', '$.#{safe_key}')" ]
      end
    end

    # WHERE condition: JSON field value is blank.
    def self.empty_condition(column, key)
      col = extract(column, key)
      [ "TRIM(COALESCE(#{col}, '')) = ''" ]
    end

    # WHERE condition: JSON field value exactly matches.
    def self.exact_condition(column, key, value, case_sensitive)
      col = extract(column, key)
      if case_sensitive
        if postgresql?
          [ "#{col} = ?", value ]
        elsif mysql?
          [ "#{col} = ? COLLATE utf8mb4_bin", value ]
        end
      else
        [ "LOWER(#{col}) = LOWER(?)", value ]
      end
    end

    # WHERE condition: JSON field value contains substring.
    def self.contains_condition(column, key, value, case_sensitive)
      col = extract(column, key)
      escaped = ActiveRecord::Base.sanitize_sql_like(value)

      if case_sensitive
        if postgresql?
          [ "#{col} LIKE ?", "%#{escaped}%" ]
        elsif mysql?
          [ "#{col} LIKE ? COLLATE utf8mb4_bin", "%#{escaped}%" ]
        end
      else
        [ "LOWER(#{col}) LIKE LOWER(?)", "%#{escaped}%" ]
      end
    end

    # WHERE condition: value exists as an element in any array within a JSON object.
    # Useful when the JSON structure is { "col" => ["err1", "err2"], ... } and you
    # want to find rows where a specific string appears in any of those arrays.
    # Returns a [sql, *binds] array suitable for .where(*condition).
    def self.any_array_value_condition(column, value)
      if postgresql?
        escaped = ActiveRecord::Base.sanitize_sql_like(value)
        [ "#{column}::text LIKE ?", "%\"#{escaped}\"%" ]
      elsif mysql?
        [ "JSON_SEARCH(#{column}, 'one', ?) IS NOT NULL", value ]
      end
    end

    # SET clause for update_all: sets one JSON field to a scalar value.
    # Returns a [sql_fragment, *binds] array.
    # Usage: sql, *binds = json_set_sql("row_data", "category", "other")
    #        Model.where(...).update_all(["corrected_at = ?, #{sql}", Time.current, *binds])
    def self.json_set_sql(column, key, value)
      safe_key = sanitize_key(key)

      if postgresql?
        [ "#{column} = jsonb_set(#{column}, ?, ?::jsonb)", "{#{safe_key}}", value.to_json ]
      elsif mysql?
        [ "#{column} = JSON_SET(#{column}, '$.#{safe_key}', ?)", value ]
      end
    end

    # SQL fragment for extracting a JSON field as text.
    # Used internally and by callers that need raw SQL.
    def self.extract(column, key)
      safe_key = sanitize_key(key)

      if postgresql?
        "#{column}->>'#{safe_key}'"
      elsif mysql?
        "JSON_UNQUOTE(JSON_EXTRACT(#{column}, '$.#{safe_key}'))"
      end
    end

    def self.adapter_name
      @adapter_name ||= fetch_adapter_name
    end

    def self.fetch_adapter_name
      name = ActiveRecord::Base.connection.adapter_name
      validate_adapter!(name)
      name
    end

    def self.postgresql?
      adapter_name == "PostgreSQL"
    end

    def self.mysql?
      %w[Mysql2 Trilogy].include?(adapter_name)
    end

    class UnsupportedAdapterError < StandardError; end

    private_class_method def self.validate_adapter!(name)
      return if SUPPORTED_ADAPTERS.include?(name)

      raise UnsupportedAdapterError,
            "Unsupported database adapter: #{name}. Rowdy requires PostgreSQL or MySQL."
    end

    private_class_method def self.sanitize_key(key)
      key.to_s.gsub(/[^a-zA-Z0-9_]/, "")
    end
  end
end
