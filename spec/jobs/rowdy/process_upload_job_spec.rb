require "rails_helper"

module Rowdy
  RSpec.describe ProcessUploadJob, type: :job do
    it "is queued on rowdy_processing" do
      expect(described_class.new.queue_name).to eq("rowdy_processing")
    end

    it "marks upload as failed when ProcessUpload returns a failure context" do
      upload = create(:rowdy_upload, :completed)
      original_call = ProcessUpload.method(:call)
      failure_ctx = LightService::Context.make.tap(&:fail!)

      ProcessUpload.define_singleton_method(:call) { |**| failure_ctx }
      described_class.perform_now(upload.id)

      expect(upload.reload).to be_failed
    ensure
      ProcessUpload.define_singleton_method(:call, original_call)
    end

    it "does not raise if upload no longer exists when processing fails" do
      original_call = ProcessUpload.method(:call)
      failure_ctx = LightService::Context.make.tap(&:fail!)

      ProcessUpload.define_singleton_method(:call) { |**| failure_ctx }
      expect { described_class.perform_now(0) }.not_to raise_error
    ensure
      ProcessUpload.define_singleton_method(:call, original_call)
    end
  end
end
