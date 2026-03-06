module Rowdy
  class ImportError < ApplicationRecord
    belongs_to :import, class_name: "Rowdy::Import"

    validates :row_number, presence: true

    # Soft-delete: corrected rows are kept for auditing. Use :active in all user-facing queries.
    scope :active, -> { where(corrected_at: nil) }
    scope :corrected, -> { where.not(corrected_at: nil) }
  end
end
