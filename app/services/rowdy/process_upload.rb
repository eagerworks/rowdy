module Rowdy
  module ProcessUpload
    extend LightService::Organizer

    def self.call(upload_id:)
      with(upload_id: upload_id).reduce(
        LoadUpload,
        MarkAsProcessing,
        DownloadInputFile,
        DetectAndStoreColumns,
        ProcessFile,
        AttachOutputFile,
        MarkAsCompleted,
        CleanupTempfiles
      )
    end
  end
end
