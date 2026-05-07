module Rowdy
  class Configuration
    attr_accessor :processor, :default_chunk_size, :chunks_storage_path,
                  :max_file_size, :orphan_cleanup_hours,
                  :schemas, :import_batch_size, :progress_broadcast_interval,
                  :import_queue, :action_label, :action_href, :action_data

    def initialize
      @processor = default_processor
      @default_chunk_size = 5 * 1024 * 1024       # 5 MB
      @chunks_storage_path = nil                    # defaults to Rails.root.join("tmp/rowdy_chunks")
      @max_file_size = 500 * 1024 * 1024           # 500 MB
      @orphan_cleanup_hours = 24
      @schemas = []
      @import_batch_size = 1000
      @progress_broadcast_interval = 5000
      @import_queue = "rowdy_imports"
      @action_label = nil
      @action_href = nil
      @action_data = {}
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
