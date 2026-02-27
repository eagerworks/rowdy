require "rails_helper"

module Rowdy
  RSpec.describe CleanupOrphanedChunksJob, type: :job do
    let(:tmp_dir) { Dir.mktmpdir("rowdy_orphan_spec") }

    before { Rowdy.configuration.chunks_storage_path = tmp_dir }
    after do
      FileUtils.rm_rf(tmp_dir)
      Rowdy.configuration.chunks_storage_path = nil
    end

    def attach_dummy_file(upload)
      upload.input_file.attach(
        io: StringIO.new("dummy"),
        filename: upload.filename,
        content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      )
    end

    context "when uploads are old" do
      it "marks uploads as failed" do
        freeze_time do
          old_upload = create(:rowdy_upload)
          attach_dummy_file(old_upload)
          old_upload.update_columns(
            status: Upload.statuses[:uploading],
            updated_at: (Rowdy.configuration.orphan_cleanup_hours + 1).hours.ago
          )

          described_class.perform_now

          expect(old_upload.reload).to be_failed
        end
      end
    end

    context "when uploads are recent" do
      it "does not touch recent uploading uploads" do
        freeze_time do
          recent_upload = create(:rowdy_upload)
          recent_upload.update_column(:updated_at, 1.hour.ago)

          described_class.perform_now

          expect(recent_upload.reload).to be_uploading
        end
      end
    end

    it "cleans up chunks_dir for orphaned uploads" do
      freeze_time do
        chunks_dir = File.join(tmp_dir, "orphan_chunks")
        FileUtils.mkdir_p(chunks_dir)

        old_upload = create(:rowdy_upload, chunks_dir: chunks_dir)
        attach_dummy_file(old_upload)
        old_upload.update_columns(
          status: Upload.statuses[:uploading],
          updated_at: (Rowdy.configuration.orphan_cleanup_hours + 1).hours.ago
        )

        described_class.perform_now

        expect(Dir.exist?(chunks_dir)).to be(false)
      end
    end

    it "does not process non-uploading uploads" do
      freeze_time do
        completed_upload = create(:rowdy_upload, :completed)
        completed_upload.update_column(
          :updated_at,
          (Rowdy.configuration.orphan_cleanup_hours + 1).hours.ago
        )

        described_class.perform_now

        expect(completed_upload.reload).to be_completed
      end
    end
  end
end
