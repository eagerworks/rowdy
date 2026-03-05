module Rowdy
  class ImportError < ApplicationRecord
    belongs_to :import, class_name: "Rowdy::Import"

    validates :row_number, presence: true

    scope :active, -> { where(corrected_at: nil) }
  end
end
