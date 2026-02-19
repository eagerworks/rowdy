module Rowdy
  class ValidateImportJob < ApplicationJob
    queue_as :rowdy_imports

    def perform(import_id)
      ValidateImport.call(import_id: import_id)
    rescue => e
      Import.find_by(id: import_id)&.update!(
        status: :failed,
        error_message: e.message
      )
    end
  end
end
