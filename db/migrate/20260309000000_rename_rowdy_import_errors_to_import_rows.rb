class RenameRowdyImportErrorsToImportRows < ActiveRecord::Migration[8.1]
  def change
    rename_table :rowdy_import_errors, :rowdy_import_rows
  end
end
