class RenameErrorsColumnInRowdyImportErrors < ActiveRecord::Migration[8.1]
  def change
    rename_column :rowdy_import_errors, :errors, :column_errors
  end
end
