module Rowdy
  module MigrationHelpers
    private

    def rowdy_json_type
      case connection.adapter_name
      when "PostgreSQL" then :jsonb
      else :json
      end
    end

    def rowdy_mysql?
      connection.adapter_name.in?(%w[Mysql2 Trilogy])
    end

    def rowdy_supports_json_defaults?
      !rowdy_mysql?
    end

    def rowdy_change_to_json(table, *columns)
      columns.each do |col|
        if connection.adapter_name == "PostgreSQL"
          change_column table, col, :jsonb, using: "#{col}::jsonb"
        else
          change_column table, col, :json
        end
      end
    end
  end
end
