FactoryBot.define do
  factory :rowdy_import_row, class: 'Rowdy::ImportRow' do
    association :import, factory: :rowdy_import, strategy: :create
    row_number    { 2 }
    row_data      { { 'name' => 'T-Shirt', 'sku' => nil } }
    column_errors { { 'sku' => [ "can't be blank" ] } }

    trait :valid_row do
      column_errors { nil }
    end

    trait :corrected do
      corrected_at { Time.current }
      column_errors { nil }
    end
  end
end
