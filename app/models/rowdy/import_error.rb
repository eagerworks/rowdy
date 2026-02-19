module Rowdy
  class ImportError < ApplicationRecord
    belongs_to :import, class_name: "Rowdy::Import"

    serialize :row_data, coder: JSON
    serialize :errors, coder: JSON

    validates :row_number, presence: true
  end
end
