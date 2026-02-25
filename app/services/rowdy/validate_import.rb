module Rowdy
  module ValidateImport
    extend LightService::Organizer

    def self.call(import_id:)
      with(import_id: import_id).reduce(
        LoadImport,
        MarkAsPreparing,
        DownloadInputFile,
        StreamAndValidate,
        GenerateErrorReport,
        MarkAsValidated,
        CleanupTempfiles
      )
    end
  end
end
