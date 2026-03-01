module Rowdy
  module ValidateImport
    class MarkAsValidating
      extend LightService::Action

      expects :import

      executed do |ctx|
        ctx.import.update!(status: :validating)
      end
    end
  end
end
