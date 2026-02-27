require "rails_helper"

module Rowdy
  RSpec.describe ValidateImportJob, type: :job do
    it "is queued on rowdy_imports" do
      expect(described_class.new.queue_name).to eq("rowdy_imports")
    end

    describe "#perform" do
      context "when validation succeeds" do
        it "does not mark the import as failed" do
          import = create(:rowdy_import)
          allow(ValidateImport).to receive(:call)

          described_class.perform_now(import.id)

          expect(import.reload).not_to be_failed
        end
      end

      context "when an exception is raised" do
        it "marks the import as failed with the error message" do
          import = create(:rowdy_import)
          allow(ValidateImport).to receive(:call).and_raise("something went wrong")

          described_class.perform_now(import.id)

          import.reload
          expect(import).to be_failed
          expect(import.error_message).to eq("something went wrong")
        end

        it "does not raise when the import no longer exists" do
          allow(ValidateImport).to receive(:call).and_raise("error")

          expect { described_class.perform_now(0) }.not_to raise_error
        end
      end
    end
  end
end
