class CreateRowdyImportErrors < ActiveRecord::Migration[8.1]
  def change
    create_table :rowdy_import_errors do |t|
      t.references :import, null: false, foreign_key: { to_table: :rowdy_imports }
      t.integer :row_number, null: false
      t.text :row_data
      t.text :errors

      t.timestamps
    end

    add_index :rowdy_import_errors, [ :import_id, :row_number ]
  end
end
