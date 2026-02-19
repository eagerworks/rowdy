class CreateRowdyImports < ActiveRecord::Migration[8.1]
  def change
    create_table :rowdy_imports do |t|
      t.references :upload, null: false, foreign_key: { to_table: :rowdy_uploads }
      t.string :schema_name, null: false
      t.integer :status, null: false, default: 0
      t.text :column_mapping
      t.integer :total_rows, default: 0
      t.integer :valid_rows_count, default: 0
      t.integer :invalid_rows_count, default: 0
      t.integer :progress, default: 0
      t.text :error_message

      t.timestamps
    end

    add_index :rowdy_imports, :schema_name
    add_index :rowdy_imports, :status
  end
end
