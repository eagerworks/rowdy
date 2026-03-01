module Rowdy
  module ValidateImport
    class CleanupTempfiles
      extend LightService::Action

      executed do |ctx|
        tempfile = ctx.fetch(:tempfile, nil)
        tempfile&.close
        tempfile&.unlink
      end
    end
  end
end
