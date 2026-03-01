FactoryBot.define do
  factory :rowdy_import, class: "Rowdy::Import" do
    association :upload, factory: :rowdy_upload, strategy: :create
    schema_name    { "product_import" }
    status         { :mapping }
    column_mapping { nil }

    trait :with_mapping do
      status { :preparing }
      column_mapping { { "name" => "name", "sku" => "sku", "price" => "price" } }
    end

    trait :validated do
      status             { :validated }
      progress           { 100 }
      total_rows         { 10 }
      valid_rows_count   { 8 }
      invalid_rows_count { 2 }
    end
  end
end
