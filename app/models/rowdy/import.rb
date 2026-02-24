module Rowdy
  class Import < ApplicationRecord
    belongs_to :upload, class_name: "Rowdy::Upload"
    has_many :import_errors, class_name: "Rowdy::ImportError", dependent: :delete_all
    has_one_attached :error_report

    serialize :column_mapping, coder: JSON

    enum :status, {
      mapping: 0,
      validating: 1,
      validated: 2,
      importing: 3,
      imported: 4,
      failed: 5
    }, default: :mapping

    validates :schema_name, presence: true

    after_update_commit :broadcast_import_update, if: :import_state_changed?

    def schema
      SchemaRegistry.find!(schema_name)
    end

    def current_step
      case status.to_sym
      when :mapping then 1
      when :validating, :validated then 2
      when :importing, :imported then 3
      when :failed then current_step_on_failure
      end
    end

    private

    def import_state_changed?
      saved_change_to_status? || saved_change_to_progress?
    end

    def current_step_on_failure
      return 1 if column_mapping.blank?
      return 2 if total_rows.zero?

      3
    end

    def broadcast_import_update
      Turbo::StreamsChannel.broadcast_replace_to(
        "rowdy_import_#{id}",
        target: "rowdy-import-step-indicator-#{id}",
        html: render_step_indicator
      )

      if validating?
        Turbo::StreamsChannel.broadcast_replace_to(
          "rowdy_import_#{id}",
          target: "rowdy-import-progress-#{id}",
          html: render_validation_progress
        )
      end
    end

    def render_step_indicator
      Rowdy::ApplicationController.render(
        partial: "rowdy/imports/step_indicator",
        locals: { import: self }
      )
    end

    def render_validation_progress
      Rowdy::ApplicationController.render(
        partial: "rowdy/imports/validation_progress",
        locals: { import: self }
      )
    end
  end
end
