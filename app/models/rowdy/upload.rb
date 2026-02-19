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

    after_create_commit :broadcast_new_upload
    after_update_commit :broadcast_upload_update, if: :status_changed?

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

    def broadcast_new_upload
      Turbo::StreamsChannel.broadcast_append_to(
        "rowdy_uploads",
        target: "rowdy-uploads-list",
        html: render_component
      )
    end

    def broadcast_upload_update
      Turbo::StreamsChannel.broadcast_replace_to(
        "rowdy_uploads",
        target: dom_id,
        html: render_component
      )
    end

    def status_changed?
      saved_change_to_status?
    end

    def dom_id
      "rowdy_upload_#{id}"
    end

    def render_component
      Rowdy::ApplicationController.render(
        Rowdy::UploadItemComponent.new(upload: self),
        layout: false
      )
    end
  end
end
