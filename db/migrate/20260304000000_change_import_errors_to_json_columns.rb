require "rowdy/migration_helpers"

class ChangeImportErrorsToJsonColumns < ActiveRecord::Migration[8.1]
  include Rowdy::MigrationHelpers

  def up
    rowdy_change_to_json :rowdy_import_errors, :row_data, :column_errors

    if connection.adapter_name == "PostgreSQL"
      add_index :rowdy_import_errors, :column_errors, using: :gin
    end
  end

  def down
    remove_index :rowdy_import_errors, :column_errors if connection.adapter_name == "PostgreSQL"
    change_column :rowdy_import_errors, :row_data, :text
    change_column :rowdy_import_errors, :column_errors, :text
  end
end
