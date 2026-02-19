module Rowdy
  class Configuration
    attr_accessor :processor, :default_chunk_size, :chunks_storage_path,
                  :max_file_size, :orphan_cleanup_hours

    def initialize
      @processor = default_processor
      @default_chunk_size = 5 * 1024 * 1024       # 5 MB
      @chunks_storage_path = nil                    # defaults to Rails.root.join("tmp/rowdy_chunks")
      @max_file_size = 500 * 1024 * 1024           # 500 MB
      @orphan_cleanup_hours = 24
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
