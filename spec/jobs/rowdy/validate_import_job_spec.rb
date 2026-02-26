require "rails_helper"

module Rowdy
  RSpec.describe ValidateImportJob, type: :job do
    it "is queued on rowdy_imports" do
      expect(described_class.new.queue_name).to eq("rowdy_imports")
    end

    it "marks import as failed with error message when an exception is raised" do
      import = create(:rowdy_import)
      original_call = ValidateImport.method(:call)

      ValidateImport.define_singleton_method(:call) { |**| raise "something went wrong" }
      described_class.perform_now(import.id)

      import.reload
      expect(import).to be_failed
      expect(import.error_message).to eq("something went wrong")
    ensure
      ValidateImport.define_singleton_method(:call, original_call)
    end

    it "does not raise if import no longer exists when an exception is raised" do
      original_call = ValidateImport.method(:call)

      ValidateImport.define_singleton_method(:call) { |**| raise "error" }
      expect { described_class.perform_now(0) }.not_to raise_error
    ensure
      ValidateImport.define_singleton_method(:call, original_call)
    end
  end
end
