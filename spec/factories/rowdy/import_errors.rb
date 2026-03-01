FactoryBot.define do
  factory :rowdy_import_error, class: "Rowdy::ImportError" do
    association :import, factory: :rowdy_import, strategy: :create
    row_number    { 2 }
    row_data      { { "name" => "T-Shirt", "sku" => nil } }
    column_errors { { "sku" => [ "can't be blank" ] } }
  end
end
