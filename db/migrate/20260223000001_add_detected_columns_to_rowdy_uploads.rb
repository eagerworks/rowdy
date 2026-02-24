class AddDetectedColumnsToRowdyUploads < ActiveRecord::Migration[8.1]
  def change
    add_column :rowdy_uploads, :detected_columns, :text
    add_column :rowdy_uploads, :sample_rows, :text
  end
end
