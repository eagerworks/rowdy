class AddCorrectedAtToRowdyImportErrors < ActiveRecord::Migration[8.1]
  def change
    add_column :rowdy_import_errors, :corrected_at, :datetime
  end
end
