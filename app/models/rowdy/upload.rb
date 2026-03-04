module Rowdy
  class Upload < ApplicationRecord
    has_one_attached :input_file
    has_one_attached :output_file
    has_many :imports, class_name: "Rowdy::Import", dependent: :destroy

    serialize :metadata, coder: JSON
    serialize :received_chunks, coder: JSON
    serialize :detected_columns, coder: JSON
    serialize :sample_rows, coder: JSON

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

    def avg_bytes_per_row
      return nil if sample_rows.blank?

      total_bytes = sample_rows.sum { |row| row.to_json.bytesize }
      (total_bytes.to_f / sample_rows.size).round
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
      Turbo::StreamsChannel.broadcast_prepend_to(
        broadcast_channel,
        target: broadcast_list_target,
        html: render_component
      )
    end

    def broadcast_upload_update
      Turbo::StreamsChannel.broadcast_replace_to(
        broadcast_channel,
        target: dom_id,
        html: render_component
      )
    end

    def broadcast_channel
      schema_name.present? ? "rowdy_uploads_#{schema_name}" : "rowdy_uploads"
    end

    def broadcast_list_target
      schema_name.present? ? "rowdy-uploads-list-items-#{schema_name}" : "rowdy-uploads-list-items"
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
