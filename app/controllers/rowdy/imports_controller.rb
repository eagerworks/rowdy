module Rowdy
  class ImportsController < ApplicationController
    before_action :set_import, only: %i[show mapping save_mapping validate validation correct_errors error_report replace_all]

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
      ValidateImport::MarkAsPreparing.call(@import.id)

      ValidateImportJob.perform_later(@import.id)

      head :no_content
    end

    def validation
      @page = (params[:page] || 1).to_i
      @errors = @import.import_errors.active.order(:row_number).offset((@page - 1) * per_page).limit(per_page)
      @total_pages = total_pages_for(@import)
      @errored_columns = ErroredColumnsQuery.call(@import)
    end

    def replace_all
      params = replace_all_params
      ReplaceAll.call(
        import: @import,
        column: params[:column],
        find_value: params[:find_value].to_s,
        replace_value: params[:replace_value].to_s,
        all_empty: params[:all_empty] == "1",
        case_sensitive: params[:case_sensitive] == "1",
        exact_match: params[:exact_match] == "1"
      )
      redirect_to import_validation_path(@import)
    end

    def correct_errors
      corrections = params[:corrections]&.to_unsafe_h || {}
      schema = @import.schema

      corrections.each do |error_id, new_values|
        import_error = @import.import_errors.active.find_by(id: error_id)
        next unless import_error

        updated_row = import_error.row_data.merge(new_values)

        # row_data and new_values both have string keys after JSON deserialization
        # and HTTP params respectively. RowValidator accesses values via col.name
        # (a Symbol from the schema DSL), so keys must be symbolized before validating.
        column_errors = RowValidator.call(updated_row.transform_keys(&:to_sym), schema)

        if column_errors.empty?
          import_error.update!(corrected_at: Time.current, row_data: updated_row)
          @import.decrement!(:invalid_rows_count)
          @import.increment!(:valid_rows_count)
        else
          import_error.update!(row_data: updated_row, column_errors:)
        end
      end

      redirect_to Rowdy::Engine.routes.url_helpers.validation_import_path(@import, page: params[:page])
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

    def replace_all_params
      params.permit(:column, :find_value, :replace_value, :all_empty, :case_sensitive, :exact_match)
    end
  end
end
