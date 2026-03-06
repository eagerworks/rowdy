class CreateRowdySchemaDefinitions < ActiveRecord::Migration[8.1]
  def change
    create_table :rowdy_schema_definitions do |t|
      t.string :name, null: false
      t.string :label
      t.text :columns_config, null: false

      t.timestamps
    end

    add_index :rowdy_schema_definitions, :name, unique: true
  end
end
