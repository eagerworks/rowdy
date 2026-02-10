require "test_helper"

module Rowdy
  class UploadTest < ActiveSupport::TestCase
    # Test: Status enums and predicates
    test "should have valid statuses" do
      upload = rowdy_uploads(:pending_upload)

      assert upload.pending?
      assert_not upload.processing?
      assert_not upload.completed?
      assert_not upload.failed?
    end

    test "processing upload should have correct status" do
      upload = rowdy_uploads(:processing_upload)

      assert upload.processing?
      assert_not upload.pending?
      assert_equal 45, upload.progress
    end

    test "completed upload should have correct status" do
      upload = rowdy_uploads(:completed_upload)

      assert upload.completed?
      assert_equal 100, upload.progress
    end

    test "failed upload should have correct status" do
      upload = rowdy_uploads(:failed_upload)

      assert upload.failed?
      assert_equal "Invalid file format", upload.error_message
    end

    # Test: Status transitions
    test "should transition from pending to processing" do
      upload = rowdy_uploads(:pending_upload)
      upload.update!(status: :processing, progress: 10)

      assert upload.processing?
      assert_equal 10, upload.progress
    end

    test "should transition from processing to completed" do
      upload = rowdy_uploads(:processing_upload)
      upload.update!(status: :completed, progress: 100)

      assert upload.completed?
      assert_equal 100, upload.progress
    end

    test "should transition from processing to failed" do
      upload = rowdy_uploads(:processing_upload)
      upload.update!(status: :failed, error_message: "Test error")

      assert upload.failed?
      assert_equal "Test error", upload.error_message
    end

    # Test: Validations
    test "should validate presence of filename" do
      upload = Rowdy::Upload.new(size: 1000)

      assert_not upload.valid?
      assert_includes upload.errors[:filename], "can't be blank"
    end

    test "should validate presence of size" do
      upload = Rowdy::Upload.new(filename: "test.xlsx")

      assert_not upload.valid?
      assert_includes upload.errors[:size], "can't be blank"
    end

    test "should validate size is positive" do
      upload = Rowdy::Upload.new(filename: "test.xlsx", size: 0)

      assert_not upload.valid?
      assert_includes upload.errors[:size], "must be greater than 0"
    end

    test "should be valid with filename and size" do
      upload = Rowdy::Upload.new(filename: "valid.xlsx", size: 1024)

      assert upload.valid?
    end

    # Test: Metadata serialization
    test "should serialize metadata as JSON" do
      upload = Rowdy::Upload.create!(
        filename: "test.xlsx",
        size: 1000,
        metadata: { key: "value", count: 42, nested: { data: "test" } }
      )

      upload.reload
      assert_equal({ "key" => "value", "count" => 42, "nested" => { "data" => "test" } }, upload.metadata)
    end

    test "should handle empty metadata" do
      upload = Rowdy::Upload.create!(
        filename: "test.xlsx",
        size: 1000,
        metadata: {}
      )

      upload.reload
      assert_equal({}, upload.metadata)
    end

    test "should initialize with empty metadata hash" do
      upload = Rowdy::Upload.create!(
        filename: "test.xlsx",
        size: 1000
      )

      upload.reload
      # Metadata should be empty hash by default, not nil
      assert_equal({}, upload.metadata)
    end

    # Test: Default values
    test "should have default status of pending" do
      upload = Rowdy::Upload.create!(filename: "test.xlsx", size: 1000)

      assert upload.pending?
    end

    test "should have default progress of 0" do
      upload = Rowdy::Upload.create!(filename: "test.xlsx", size: 1000)

      assert_equal 0, upload.progress
    end

    # Test: Progress updates
    test "should allow progress updates from 0 to 100" do
      upload = rowdy_uploads(:processing_upload)

      [0, 25, 50, 75, 100].each do |progress_value|
        upload.update!(progress: progress_value)
        assert_equal progress_value, upload.progress
      end
    end

    # Test: Error message handling
    test "should store error message on failure" do
      upload = rowdy_uploads(:processing_upload)
      error_msg = "Processing failed: Invalid data in row 42"

      upload.update!(status: :failed, error_message: error_msg)

      assert upload.failed?
      assert_equal error_msg, upload.error_message
    end

    test "should allow nil error message for non-failed uploads" do
      upload = rowdy_uploads(:completed_upload)

      assert_nil upload.error_message
    end
  end
end
