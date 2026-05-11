module Rowdy
  class ImportsController < ApplicationController
    before_action :set_import, only: %i[show correct_errors error_report valid_rows_report replace_all]

    helper_method :import_show_path, :upload_schema_path

    def index
      @upload = Upload.find(params[:upload_id])
      @imports = @upload.imports.order(created_at: :desc)
      @imports = params[:hide_imported] ? @imports.not_imported : @imports

      @list_frame = params[:list_frame].presence || "rowdy-container"
    end

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
      when 1 then redirect_to import_mapping_path(@import, frame_id: params[:frame_id])
      when 2 then redirect_to import_validation_path(@import, frame_id: params[:frame_id])
      else redirect_to import_mapping_path(@import, frame_id: params[:frame_id])
      end
    end

    def correct_errors
      corrections = params[:corrections]&.to_unsafe_h || {}
      schema      = @import.schema
      now         = Time.current
      updates     = []
      corrected_count = 0

      corrections.each do |error_id, new_values|
        import_row = @import.import_rows.errored.active.find_by(id: error_id)
        next unless import_row

        updated_row   = import_row.row_data.merge(new_values)
        column_errors = RowValidator.call(updated_row, schema, import_row:, column_mapping: @import.column_mapping, corrections:)

        if column_errors.empty?
          corrected_count += 1
          updates << {
            id:            import_row.id,
            import_id:     import_row.import_id,
            row_number:    import_row.row_number,
            row_data:      updated_row,
            column_errors: nil,
            corrected_at:  now,
            created_at:    import_row.created_at,
            updated_at:    now
          }
        else
          updates << {
            id:            import_row.id,
            import_id:     import_row.import_id,
            row_number:    import_row.row_number,
            row_data:      updated_row,
            column_errors: column_errors,
            corrected_at:  nil,
            created_at:    import_row.created_at,
            updated_at:    now
          }
        end
      end

      if updates.any?
        ImportRow.upsert_all(
          updates,
          unique_by: :id,
          update_only: %i[corrected_at row_data column_errors]
        )
      end

      if corrected_count > 0
        @import.update_columns(
          invalid_rows_count: @import.invalid_rows_count - corrected_count,
          valid_rows_count:   @import.valid_rows_count   + corrected_count
        )
      end

      redirect_to import_validation_path(@import, page: params[:page], current_tab: params[:current_tab], frame_id: params[:frame_id])
    end

    def replace_all
      rp = replace_all_params
      column = rp[:column]
      find_value = rp[:find_value].to_s
      replace_value = rp[:replace_value].to_s
      match_empty = rp[:all_empty] == "1"
      case_sensitive = rp[:case_sensitive] == "1"
      exact = rp[:exact_match] == "1"
      schema = @import.schema

      ReplaceAll.new(
        import: @import,
        column:,
        find_value:,
        replace_value:,
        all_empty: match_empty,
        case_sensitive:,
        exact_match: exact
      ).call

      redirect_to import_validation_path(@import, frame_id: params[:frame_id])
    end

    def valid_rows_report
      tempfile = GenerateValidRowsReport.new(@import).call
      send_data File.read(tempfile.path),
        filename: "valid_rows_#{@import.id}.csv",
        type: "text/csv",
        disposition: "attachment"
    ensure
      tempfile&.close
      tempfile&.unlink
    end

    def error_report
      unless @import.error_report.attached?
        redirect_to import_validation_path(@import)
        return
      end

      redirect_to main_app.rails_blob_path(@import.error_report, disposition: "attachment")
    end

    private

    def set_import
      @import = Import.find(params[:id])
    end

    def upload_schema_path(upload)
      Rowdy::Engine.routes.url_helpers.schema_path(upload.schema_name)
    end

    def import_show_path(import, **opts)
      Rowdy::Engine.routes.url_helpers.import_path(import, **opts)
    end

    def import_mapping_path(import, **opts)
      Rowdy::Engine.routes.url_helpers.import_mapping_path(import, **opts)
    end

    def import_validation_path(import, **opts)
      Rowdy::Engine.routes.url_helpers.import_validation_path(import, **opts)
    end

    def replace_all_params
      params.permit(:column, :find_value, :replace_value, :all_empty, :case_sensitive, :exact_match)
    end

    def value_matches?(current, find_value, match_empty:, case_sensitive:, exact:)
      return current.blank? if match_empty

      if exact
        case_sensitive ? current == find_value : current.casecmp(find_value).zero?
      else
        case_sensitive ? current.include?(find_value) : current.downcase.include?(find_value.downcase)
      end
    end

    def compute_replacement(current, find_value, replace_value, match_empty:, case_sensitive:, exact:)
      return replace_value if match_empty || exact

      if case_sensitive
        current.gsub(find_value, replace_value)
      else
        current.gsub(/#{Regexp.escape(find_value)}/i, replace_value)
      end
    end
  end
end
