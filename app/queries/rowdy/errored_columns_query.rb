module Rowdy
  class ErroredColumnsQuery
    def self.call(import)
      new(import).call
    end

    def initialize(import)
      @import = import
    end

    def call
      @import.import_rows.errored.active
        .pluck(:column_errors)
        .flat_map { |ie| (ie || {}).keys }
        .uniq.sort
    end
  end
end
