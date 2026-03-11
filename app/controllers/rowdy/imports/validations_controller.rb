module Rowdy
  module Imports
    class ValidationsController < ApplicationController
      before_action :set_import

      def show
        @page = (params[:page] || 1).to_i
        @tab  = (params[:tab]  || 0).to_i

        ids_by_column = classified_ids_by_column

        @error_types_with_counts = ids_by_column
          .sort_by { |col, _| col }
          .map { |col, ids| [col, ids.size] }

        active_column = @error_types_with_counts[@tab]&.first
        active_ids    = ids_by_column[active_column] || []

        @errors = @import.import_errors.active
          .where(id: active_ids)
          .order(:row_number)
          .offset((@page - 1) * per_page)
          .limit(per_page)

        @total_pages     = (active_ids.size.to_f / per_page).ceil
        @errored_columns = @error_types_with_counts.map(&:first)

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

      def classified_ids_by_column
        result = Hash.new { |h, k| h[k] = [] }
        @import.import_errors.active.pluck(:id, :column_errors).each do |id, errors|
          messages = Set.new
          (errors || {}).each_value { |msgs| Array(msgs).each { |msg| messages.add(msg) } }
          messages.each { |msg| result[msg] << id }
        end
        result
      end
    end
  end
end
