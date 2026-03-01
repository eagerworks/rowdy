require "rails_helper"

module Rowdy
  RSpec.describe ProcessUploadJob, type: :job do
    it "is queued on rowdy_processing" do
      expect(described_class.new.queue_name).to eq("rowdy_processing")
    end

    describe "#perform" do
      context "when processing succeeds" do
        it "does not mark the upload as failed" do
          upload = create(:rowdy_upload)
          allow(ProcessUpload).to receive(:call).and_return(LightService::Context.make)

          described_class.perform_now(upload.id)

          expect(upload.reload).not_to be_failed
        end
      end

      context "when processing fails" do
        it "marks the upload as failed" do
          upload = create(:rowdy_upload, :completed)
          failure_ctx = LightService::Context.make.tap(&:fail!)
          allow(ProcessUpload).to receive(:call).and_return(failure_ctx)

          described_class.perform_now(upload.id)

          expect(upload.reload).to be_failed
        end

        it "does not raise when the upload no longer exists" do
          failure_ctx = LightService::Context.make.tap(&:fail!)
          allow(ProcessUpload).to receive(:call).and_return(failure_ctx)

          expect { described_class.perform_now(0) }.not_to raise_error
        end
      end
    end
  end
end
