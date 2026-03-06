module Rowdy
  module Imports
    class ValidationsController < ApplicationController
      before_action :set_import

      def show
        @page = (params[:page] || 1).to_i
        @errors = @import.import_errors.active.order(:row_number).offset((@page - 1) * per_page).limit(per_page)
        @total_pages = total_pages_for(@import)
        @errored_columns = @import.import_errors.active
          .pluck(:column_errors)
          .compact
          .flat_map(&:keys)
          .uniq
          .sort
        render "rowdy/imports/validation"
      end

      def create
        ValidateImport::MarkAsPreparing.call(@import.id)

        ValidateImportJob.perform_later(@import.id)

        head :no_content
      end

      private

      def set_import
        @import = Rowdy::Import.find(params[:import_id])
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
end
