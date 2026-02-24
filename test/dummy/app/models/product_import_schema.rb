class ProductImportSchema < Rowdy::Schema
  column :name,     type: :string,  required: true,  max_length: 100
  column :sku,      type: :string,  required: true,  unique: true
  column :price,    type: :decimal, required: true,  greater_than: 0
  column :stock,    type: :integer, required: false
  column :category, type: :string,  required: false, inclusion: %w[electronics clothing food other]
end
