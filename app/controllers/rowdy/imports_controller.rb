module Rowdy
  class ImportsController < ApplicationController
    before_action :set_import, only: %i[show mapping save_mapping validate validation error_report]

    def create
      upload = Upload.find(params[:upload_id])
      import = upload.imports.create!(
        schema_name: upload.schema_name,
        status: :mapping
      )

      redirect_to import_mapping_path(import)
    end

    def show
      case @import.current_step
      when 1 then redirect_to import_mapping_path(@import)
      when 2 then redirect_to import_validation_path(@import)
      else redirect_to import_mapping_path(@import)
      end
    end

    def mapping
      @detected_columns = @import.upload.detected_columns || []
      @sample_rows = @import.upload.sample_rows || []
      @schema_columns = @import.schema.columns
    end

    def save_mapping
      column_mapping = params[:column_mapping]&.to_unsafe_h || {}
      column_mapping = column_mapping.reject { |_, v| v.blank? }

      missing = check_required_columns(column_mapping)

      if missing.any?
        @detected_columns = @import.upload.detected_columns || []
        @sample_rows = @import.upload.sample_rows || []
        @schema_columns = @import.schema.columns
        @column_mapping = column_mapping
        @mapping_errors = [ I18n.t("rowdy.import.missing_required_columns", columns: missing.join(", ")) ]
        render :mapping, status: :unprocessable_entity
        return
      end

      @import.update!(column_mapping: column_mapping, status: :preparing, progress: 0)

      redirect_to import_validation_path(@import)
    end

    def validate
      ValidateImportJob.perform_now(@import.id)

      head :no_content
    end

    def validation
      @page = (params[:page] || 1).to_i
      @errors = @import.import_errors.order(:row_number).offset((@page - 1) * per_page).limit(per_page)
      @total_pages = total_pages_for(@import)
    end

    def error_report
      unless @import.error_report.attached?
        redirect_to import_validation_path(@import)
        return
      end

      redirect_to rails_blob_path(@import.error_report, disposition: "attachment")
    end

    private

    def set_import
      @import = Import.find(params[:id])
    end

    def check_required_columns(column_mapping)
      schema = @import.schema
      mapped_schema_columns = column_mapping.values.map(&:to_sym)

      schema.required_columns.map(&:name).reject do |col_name|
        mapped_schema_columns.include?(col_name)
      end
    end

    def import_mapping_path(import)
      Rowdy::Engine.routes.url_helpers.mapping_import_path(import)
    end

    def import_validation_path(import)
      Rowdy::Engine.routes.url_helpers.validation_import_path(import)
    end

    def per_page
      50
    end

    def total_pages_for(import)
      return 0 if import.invalid_rows_count.zero?

      (import.invalid_rows_count.to_f / per_page).ceil
    end
  end
end
