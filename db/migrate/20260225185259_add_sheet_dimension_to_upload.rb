class AddSheetDimensionToUpload < ActiveRecord::Migration[8.1]
  def change
    add_column :rowdy_uploads, :sheet_dimension, :string
  end
end
