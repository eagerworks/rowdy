module Rowdy
  module ValidateImport
    class CleanupTempfiles
      extend LightService::Action

      executed do |ctx|
        Array(ctx.input_path).each do |path|
          next unless path && File.exist?(path)
          File.delete(path)
        rescue => e
          Rails.logger.warn("Failed to cleanup tempfile #{path}: #{e.message}")
        end
      end
    end
  end
end
