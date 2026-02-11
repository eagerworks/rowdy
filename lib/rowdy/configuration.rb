module Rowdy
  class Configuration
    attr_accessor :processor

    def initialize
      @processor = default_processor
    end

    def default_processor
      lambda do |input_path, _upload|
        yield(50) if block_given?
        input_path
      end
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
