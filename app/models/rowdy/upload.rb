module Rowdy
  class Upload < ApplicationRecord
    has_one_attached :input_file
    has_one_attached :output_file

    serialize :metadata, coder: JSON
    serialize :received_chunks, coder: JSON

    enum :status, {
      pending: 0,
      processing: 1,
      completed: 2,
      failed: 3,
      uploading: 4
    }, default: :pending

    validates :filename, presence: true
    validates :size, presence: true, numericality: { greater_than: 0 }
    validate :input_file_attached, unless: :uploading?

    before_create :initialize_metadata
    before_create :initialize_received_chunks
    before_create :generate_upload_token

    def all_chunks_received?
      return false if received_chunks.blank? || total_chunks.blank?

      received_chunks.sort == (0...total_chunks).to_a
    end

    def upload_progress_percent
      return 0 if total_chunks.nil? || total_chunks.zero?

      ((received_chunks&.size.to_f / total_chunks) * 100).round
    end

    private

    def initialize_metadata
      self.metadata ||= {}
    end

    def initialize_received_chunks
      self.received_chunks ||= []
    end

    def generate_upload_token
      self.upload_token ||= SecureRandom.uuid
    end

    def input_file_attached
      errors.add(:input_file, "must be attached") unless input_file.attached?
    end
  end
end
