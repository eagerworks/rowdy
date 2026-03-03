# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_27_000000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "rowdy_import_errors", force: :cascade do |t|
    t.text "column_errors"
    t.datetime "corrected_at"
    t.datetime "created_at", null: false
    t.integer "import_id", null: false
    t.text "row_data"
    t.integer "row_number", null: false
    t.datetime "updated_at", null: false
    t.index ["import_id", "row_number"], name: "index_rowdy_import_errors_on_import_id_and_row_number"
    t.index ["import_id"], name: "index_rowdy_import_errors_on_import_id"
  end

  create_table "rowdy_imports", force: :cascade do |t|
    t.text "column_mapping"
    t.datetime "created_at", null: false
    t.text "error_message"
    t.integer "invalid_rows_count", default: 0
    t.integer "progress", default: 0
    t.string "schema_name", null: false
    t.integer "status", default: 0, null: false
    t.integer "total_rows", default: 0
    t.datetime "updated_at", null: false
    t.integer "upload_id", null: false
    t.integer "valid_rows_count", default: 0
    t.index ["schema_name"], name: "index_rowdy_imports_on_schema_name"
    t.index ["status"], name: "index_rowdy_imports_on_status"
    t.index ["upload_id"], name: "index_rowdy_imports_on_upload_id"
  end

  create_table "rowdy_uploads", force: :cascade do |t|
    t.integer "chunk_size"
    t.string "chunks_dir"
    t.datetime "created_at", null: false
    t.text "detected_columns"
    t.text "error_message"
    t.string "filename", null: false
    t.text "metadata"
    t.integer "progress", default: 0
    t.text "received_chunks"
    t.text "sample_rows"
    t.string "schema_name"
    t.string "sheet_dimension"
    t.bigint "size", null: false
    t.integer "status", default: 0, null: false
    t.integer "total_chunks"
    t.datetime "updated_at", null: false
    t.string "upload_token"
    t.index ["schema_name"], name: "index_rowdy_uploads_on_schema_name"
    t.index ["status"], name: "index_rowdy_uploads_on_status"
    t.index ["upload_token"], name: "index_rowdy_uploads_on_upload_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "rowdy_import_errors", "rowdy_imports", column: "import_id"
  add_foreign_key "rowdy_imports", "rowdy_uploads", column: "upload_id"
end
