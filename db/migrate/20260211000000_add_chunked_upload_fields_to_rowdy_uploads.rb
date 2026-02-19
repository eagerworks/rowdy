class AddChunkedUploadFieldsToRowdyUploads < ActiveRecord::Migration[8.1]
  def change
    add_column :rowdy_uploads, :upload_token, :string
    add_column :rowdy_uploads, :total_chunks, :integer
    add_column :rowdy_uploads, :chunk_size, :integer
    add_column :rowdy_uploads, :received_chunks, :text
    add_column :rowdy_uploads, :chunks_dir, :string

    add_index :rowdy_uploads, :upload_token, unique: true
  end
end
