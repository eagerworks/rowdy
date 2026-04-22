module Rowdy
  class ErrorMessageCountsQuery
    def self.call(import) = new(import).call

    def initialize(import)
      @import = import
    end

    def call
      result = Hash.new(0)
      @import.import_rows.active.pluck(:column_errors).each do |errors|
        (errors || {}).each_value { |msgs| Array(msgs).each { |msg| result[msg] += 1 } }
      end
      result.sort_by { |msg, _| msg }
    end
  end
end
