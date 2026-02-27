FactoryBot.define do
  factory :rowdy_upload, class: "Rowdy::Upload" do
    filename     { "products.xlsx" }
    size         { 10_240 }
    status       { :uploading }
    upload_token { SecureRandom.hex }
    total_chunks { 1 }
    chunk_size   { 10_240 }

    # Attach a dummy file and set status via update_column to bypass validation
    trait :completed do
      after(:create) do |upload|
        upload.input_file.attach(
          io: StringIO.new("dummy xlsx content"),
          filename: upload.filename,
          content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        )
        upload.update_columns(
          status: Rowdy::Upload.statuses[:completed],
          progress: 100
        )
      end
    end

    trait :with_schema do
      schema_name { "product_import" }
    end

    trait :with_columns do
      detected_columns { %w[name sku price stock category] }
      sample_rows      { [ [ "T-Shirt", "SKU1", "19.99", "100", "clothing" ] ] }
    end
  end
end
