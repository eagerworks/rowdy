module Rowdy
  class CleanupOrphanedChunksJob < ApplicationJob
    queue_as :rowdy_processing

    def perform
      cutoff = Rowdy.configuration.orphan_cleanup_hours.hours.ago

      Upload.where(status: :uploading).where("updated_at < ?", cutoff).find_each do |upload|
        ChunkStorage.cleanup(upload.chunks_dir) if upload.chunks_dir.present?
        upload.update!(status: :failed)
      end
    end
  end
end
