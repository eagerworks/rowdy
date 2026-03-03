# Builds row hashes for RowValidator specs (ProductImportSchema).
# Use: build(:rowdy_validator_row).to_h or build(:rowdy_validator_row, :with_blank_sku).to_h
ValidatorRow = Struct.new(:name, :sku, :price, :stock, :category, keyword_init: true) do
  def to_h
    super.compact.transform_keys(&:to_sym)
  end
end

FactoryBot.define do
  factory :rowdy_validator_row, class: ValidatorRow do
    name     { "T-Shirt" }
    sku      { "SKU1" }
    price    { BigDecimal("19.99") }
    stock    { 100 }
    category { "clothing" }

    trait :valid do
      # default attributes are valid
    end

    trait :with_blank_name do
      name { nil }
    end

    trait :with_blank_sku do
      sku { "  " }
    end

    trait :with_optional_nils do
      stock    { nil }
      category { nil }
    end

    trait :invalid_price_type do
      price { "not-a-number" }
    end

    trait :name_exceeds_max_length do
      name { "A" * 101 }
    end

    trait :category_outside_inclusion do
      category { "unknown" }
    end

    trait :price_not_greater_than_zero do
      price { BigDecimal("0") }
    end

    trait :duplicate_sku do
      sku { "SKU1" }
    end
  end
end
