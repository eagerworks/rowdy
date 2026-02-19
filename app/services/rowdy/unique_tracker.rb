module Rowdy
  class UniqueTracker
    def initialize
      @sets = Hash.new { |h, k| h[k] = Set.new }
    end

    def add?(column_name, value)
      !@sets[column_name].add?(value).nil?
    end

    def size_for(column_name)
      @sets[column_name].size
    end
  end
end
