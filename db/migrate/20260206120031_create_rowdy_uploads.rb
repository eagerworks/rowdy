class CreateRowdyUploads < ActiveRecord::Migration[8.1]
  def change
    create_table :rowdy_uploads do |t|
      t.string :filename, null: false
      t.bigint :size, null: false
      t.integer :status, default: 0, null: false
      t.integer :progress, default: 0
      t.text :error_message
      t.text :metadata

      t.timestamps
    end

    add_index :rowdy_uploads, :status
  end
end
