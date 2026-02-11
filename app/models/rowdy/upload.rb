module Rowdy
  class Upload < ApplicationRecord
    has_one_attached :input_file
    has_one_attached :output_file

    serialize :metadata, coder: JSON

    enum :status, {
      pending: 0,
      processing: 1,
      completed: 2,
      failed: 3
    }, default: :pending

    validates :filename, presence: true
    validates :size, presence: true, numericality: { greater_than: 0 }
    validate :input_file_attached

    before_create :initialize_metadata

    private

    def initialize_metadata
      self.metadata ||= {}
    end

    def input_file_attached
      errors.add(:input_file, "must be attached") unless input_file.attached?
    end
  end
end
