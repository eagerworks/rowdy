module Rowdy
  module Imports
    class ValidationsController < ApplicationController
      before_action :set_import

      def show
        @page        = (params[:page] || 1).to_i
        @current_tab = (params[:current_tab] || 0).to_i

        @error_types_with_counts = ErrorMessageCountsQuery.call(@import)

        active_error = @error_types_with_counts[@current_tab]&.first
        active_count = @error_types_with_counts[@current_tab]&.last || 0

        @errors = active_error \
          ? ErrorsForMessageQuery.call(@import, active_error, page: @page, per_page: per_page)
          : @import.import_errors.none

        @total_pages = (active_count.to_f / per_page).ceil
        @tabs        = @error_types_with_counts.map(&:first)

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
    end
  end
end
