class AddSchemaNameToRowdyUploads < ActiveRecord::Migration[8.1]
  def change
    add_column :rowdy_uploads, :schema_name, :string
    add_index :rowdy_uploads, :schema_name
  end
end
