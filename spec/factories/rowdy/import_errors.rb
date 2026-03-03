FactoryBot.define do
  factory :rowdy_import_error, class: "Rowdy::ImportError" do
    association :import, factory: :rowdy_import, strategy: :create
    row_number    { 2 }
    row_data      { { "name" => "T-Shirt", "sku" => nil } }
    column_errors { { "sku" => [ "can't be blank" ] } }

    trait :corrected do
      corrected_at { Time.current }
    end
  end
end
