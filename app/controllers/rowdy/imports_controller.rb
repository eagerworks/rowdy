module Rowdy
  class ImportsController < ApplicationController
    before_action :set_import, only: %i[show correct_errors error_report replace_all]

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

    def correct_errors
      corrections = params[:corrections]&.to_unsafe_h || {}
      schema = @import.schema

      corrections.each do |error_id, new_values|
        import_row = @import.import_rows.errored.active.find_by(id: error_id)
        next unless import_row

        updated_row = import_row.row_data.merge(new_values)

        # row_data and new_values both have string keys after JSON deserialization
        # and HTTP params respectively. RowValidator accesses values via col.name
        # (a Symbol from the schema DSL), so keys must be symbolized before validating.
        column_errors = RowValidator.call(updated_row.transform_keys(&:to_sym), schema)

        if column_errors.empty?
          import_row.update!(corrected_at: Time.current, row_data: updated_row, column_errors: nil)
          @import.decrement!(:invalid_rows_count)
          @import.increment!(:valid_rows_count)
        else
          import_row.update!(row_data: updated_row, column_errors:)
        end
      end

      redirect_to import_validation_path(@import, page: params[:page])
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
        column: column,
        find_value:,
        replace_value:,
        all_empty: match_empty,
        case_sensitive:,
        exact_match: exact
      ).call

      redirect_to import_validation_path(@import)
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

    def import_mapping_path(import)
      Rowdy::Engine.routes.url_helpers.import_mapping_path(import)
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
