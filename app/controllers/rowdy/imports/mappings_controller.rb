module Rowdy
  module Imports
    class MappingsController < ApplicationController
      before_action :set_import

      def show
        @detected_columns = @import.upload.detected_columns || []
        @sample_rows = @import.upload.sample_rows || []
        @schema_columns = @import.schema.columns
        render "rowdy/imports/mapping"
      end

      def update
        column_mapping = params[:column_mapping]&.to_unsafe_h || {}
        column_mapping = column_mapping.reject { |_, v| v.blank? }

        missing = check_required_columns(column_mapping)

        if missing.any?
          @detected_columns = @import.upload.detected_columns || []
          @sample_rows = @import.upload.sample_rows || []
          @schema_columns = @import.schema.columns
          @column_mapping = column_mapping
          @mapping_errors = [ I18n.t("rowdy.import.missing_required_columns", columns: missing.join(", ")) ]
          render "rowdy/imports/mapping", status: :unprocessable_entity
          return
        end

        @import.update!(column_mapping: column_mapping, status: :preparing, progress: 0)

        redirect_to import_validation_path(@import)
      end

      private

      def set_import
        @import = Rowdy::Import.find(params[:import_id])
      end

      def check_required_columns(column_mapping)
        schema = @import.schema
        mapped_schema_columns = column_mapping.values.map(&:to_sym)

        schema.required_columns.map(&:name).reject do |col_name|
          mapped_schema_columns.include?(col_name)
        end
      end

      def import_validation_path(import)
        Rowdy::Engine.routes.url_helpers.import_validation_path(import)
      end
    end
  end
end
