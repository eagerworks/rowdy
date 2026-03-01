module Rowdy
  module ValidateImport
    class MarkAsValidated
      extend LightService::Action

      expects :import

      executed do |ctx|
        ctx.import.update!(status: :validated, progress: 100)
      end
    end
  end
end
