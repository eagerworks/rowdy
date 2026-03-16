require 'rails_helper'

module Rowdy
  RSpec.describe ImportRow, type: :model do
    describe 'validations' do
      it 'is valid with required attributes' do
        expect(build(:rowdy_import_row)).to be_valid
      end

      it 'is invalid without row_number' do
        row = build(:rowdy_import_row, row_number: nil)
        expect(row).not_to be_valid
        expect(row.errors[:row_number]).to include("can't be blank")
      end
    end

    describe 'associations' do
      it 'belongs to an import' do
        expect(build(:rowdy_import_row).import).to be_a(Rowdy::Import)
      end
    end

    describe '.errored' do
      it 'includes rows with column_errors' do
        row = create(:rowdy_import_row)
        expect(described_class.errored).to include(row)
      end

      it 'excludes rows without column_errors' do
        row = create(:rowdy_import_row, :valid_row)
        expect(described_class.errored).not_to include(row)
      end
    end

    describe '.active' do
      it 'includes rows without corrected_at' do
        row = create(:rowdy_import_row)
        expect(described_class.active).to include(row)
      end

      it 'excludes rows with corrected_at set' do
        row = create(:rowdy_import_row, :corrected)
        expect(described_class.active).not_to include(row)
      end
    end

    describe 'serialization' do
      it 'serializes column_errors as JSON hash' do
        data = { 'sku' => [ 'Is required' ], 'price' => [ 'Must be greater than 0' ] }
        row = create(:rowdy_import_row, column_errors: data)
        expect(row.reload.column_errors).to eq(data)
      end

      it 'serializes row_data as JSON hash' do
        data = { 'name' => 'T-Shirt', 'sku' => nil, 'price' => 'bad' }
        row = create(:rowdy_import_row, row_data: data)
        expect(row.reload.row_data).to eq(data)
      end
    end
  end
end
