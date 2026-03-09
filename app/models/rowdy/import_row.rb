module Rowdy
  class ImportRow < ApplicationRecord
    belongs_to :import, class_name: 'Rowdy::Import'

    validates :row_number, presence: true

    scope :errored,   -> { where.not(column_errors: nil) }
    scope :active,    -> { where(corrected_at: nil) }
    scope :corrected, -> { where.not(corrected_at: nil) }

    def errored? = column_errors.present?
    def corrected? = corrected_at.present?
  end
end
