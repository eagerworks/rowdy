module Rowdy
  class ErroredColumnsQuery
    def self.call(import) = new(import).call

    def initialize(import)
      @import = import
    end

    def call
      @import.import_errors.active
        .select(:column_errors)
        .flat_map { |ie| (ie.column_errors || {}).keys }
        .uniq.sort
    end
  end
end
