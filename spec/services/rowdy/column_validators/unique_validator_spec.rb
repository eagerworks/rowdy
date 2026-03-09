# frozen_string_literal: true

require 'rails_helper'

module Rowdy
  module ColumnValidators
    RSpec.describe UniqueValidator do
      describe '.execute' do
        let(:errors) { [] }
        let(:column) { ColumnDefinition.new(name: :sku, type: :string, unique: true) }

        context 'when unique_tracker is present' do
          it 'adds no error when value is new' do
            tracker = UniqueTracker.new
            described_class.execute(value: 'SKU-001', column: column, errors: errors,
                                    unique_tracker: tracker, import_row: nil)
            expect(errors).to be_empty
          end

          it 'adds error when value was already seen' do
            tracker = UniqueTracker.new
            tracker.add?(:sku, 'SKU-001')
            described_class.execute(value: 'SKU-001', column: column, errors: errors,
                                    unique_tracker: tracker, import_row: nil)
            expect(errors).to eq([ 'Must be unique' ])
          end

          it 'tracks by column name' do
            tracker = UniqueTracker.new
            tracker.add?(:name, 'Duplicate')
            described_class.execute(value: 'Duplicate', column: column, errors: errors,
                                    unique_tracker: tracker, import_row: nil)
            expect(errors).to be_empty
          end
        end

        context 'when unique_tracker is nil and import_row is nil' do
          it 'skips validation and adds no error' do
            described_class.execute(value: 'SKU-001', column: column, errors: errors,
                                    unique_tracker: nil, import_row: nil)
            expect(errors).to be_empty
          end
        end

        context 'when unique_tracker is nil and import_row is present' do
          let(:import_row) do
            create(:rowdy_import_row,
                   row_data:      { 'sku' => 'SKU-SELF', 'name' => 'T-Shirt' },
                   column_errors: { 'sku' => [ 'is required' ] })
          end

          it 'adds no error when value does not exist in any other row' do
            described_class.execute(value: 'SKU-NEW', column: column, errors: errors,
                                    unique_tracker: nil, import_row: import_row)
            expect(errors).to be_empty
          end

          it 'adds error when value exists in another row of the same import' do
            create(:rowdy_import_row,
                   import:        import_row.import,
                   row_number:    3,
                   row_data:      { 'sku' => 'SKU-DUP', 'name' => 'Hoodie' },
                   column_errors: nil)

            described_class.execute(value: 'SKU-DUP', column: column, errors: errors,
                                    unique_tracker: nil, import_row: import_row)
            expect(errors).to include(I18n.t('rowdy.column_validators.unique'))
          end

          it 'adds error when value exists in a corrected row of the same import' do
            create(:rowdy_import_row, :corrected,
                   import:        import_row.import,
                   row_number:    3,
                   row_data:      { 'sku' => 'SKU-DUP', 'name' => 'Hoodie' })

            described_class.execute(value: 'SKU-DUP', column: column, errors: errors,
                                    unique_tracker: nil, import_row: import_row)
            expect(errors).to include(I18n.t('rowdy.column_validators.unique'))
          end

          it 'does not flag the row as a duplicate of itself' do
            described_class.execute(value: 'SKU-SELF', column: column, errors: errors,
                                    unique_tracker: nil, import_row: import_row)
            expect(errors).to be_empty
          end

          it 'does not flag a duplicate from a different import' do
            other_import = create(:rowdy_import, :validated)
            create(:rowdy_import_row,
                   import:        other_import,
                   row_number:    3,
                   row_data:      { 'sku' => 'SKU-DUP', 'name' => 'Hoodie' },
                   column_errors: nil)

            described_class.execute(value: 'SKU-DUP', column: column, errors: errors,
                                    unique_tracker: nil, import_row: import_row)
            expect(errors).to be_empty
          end
        end
      end
    end
  end
end
