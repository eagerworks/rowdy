module Rowdy
  class ErrorMessageCountsQuery
    def self.call(import) = new(import).call

    def initialize(import)
      @import = import
    end

    def call
      result = Hash.new(0)
      @import.import_errors.active.pluck(:column_errors).each do |errors|
        messages = Set.new
        (errors || {}).each_value { |msgs| Array(msgs).each { |msg| messages.add(msg) } }
        messages.each { |msg| result[msg] += 1 }
      end
      result.sort_by { |msg, _| msg }
    end
  end
end
