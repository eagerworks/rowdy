require "test_helper"

module Rowdy
  class UploadItemComponentTest < ActiveSupport::TestCase
    # Test: Pending upload rendering
    test "renders pending upload correctly" do
      upload = rowdy_uploads(:pending_upload)
      render_inline(UploadItemComponent.new(upload: upload))

      assert_selector '.rowdy-upload-item[data-upload-status="pending"]'
      assert_selector '.rowdy-upload-item[data-upload-id="' + upload.id.to_s + '"]'
      assert_text upload.filename
    end

    test "pending upload does not show progress bar" do
      upload = rowdy_uploads(:pending_upload)
      render_inline(UploadItemComponent.new(upload: upload))

      assert_no_selector '.rowdy-upload-progress-bar'
      assert_no_selector 'progress'
    end

    test "pending upload does not show download button" do
      upload = rowdy_uploads(:pending_upload)
      render_inline(UploadItemComponent.new(upload: upload))

      assert_no_selector '.rowdy-download-button'
    end

    # Test: Processing upload rendering
    test "renders processing upload correctly" do
      upload = rowdy_uploads(:processing_upload)
      render_inline(UploadItemComponent.new(upload: upload))

      assert_selector '.rowdy-upload-item[data-upload-status="processing"]'
      assert_text upload.filename
    end

    test "processing upload shows progress bar" do
      upload = rowdy_uploads(:processing_upload)
      render_inline(UploadItemComponent.new(upload: upload))

      assert_selector '.rowdy-upload-progress-bar'
      assert_selector 'progress[value="45"][max="100"]'
      assert_text "45%"
    end

    test "processing upload does not show download button" do
      upload = rowdy_uploads(:processing_upload)
      render_inline(UploadItemComponent.new(upload: upload))

      assert_no_selector '.rowdy-download-button'
    end

    # Test: Completed upload rendering
    test "renders completed upload correctly" do
      upload = rowdy_uploads(:completed_upload)
      render_inline(UploadItemComponent.new(upload: upload))

      assert_selector '.rowdy-upload-item[data-upload-status="completed"]'
      assert_text upload.filename
    end

    test "completed upload does not show progress bar" do
      upload = rowdy_uploads(:completed_upload)
      render_inline(UploadItemComponent.new(upload: upload))

      assert_no_selector '.rowdy-upload-progress-bar'
    end

    test "completed upload shows download button" do
      upload = rowdy_uploads(:completed_upload)
      render_inline(UploadItemComponent.new(upload: upload))

      assert_selector 'a.rowdy-download-button'
      assert_link I18n.t("rowdy.upload_item.download")
    end

    # Test: Failed upload rendering
    test "renders failed upload correctly" do
      upload = rowdy_uploads(:failed_upload)
      render_inline(UploadItemComponent.new(upload: upload))

      assert_selector '.rowdy-upload-item[data-upload-status="failed"]'
      assert_text upload.filename
    end

    test "failed upload shows error message" do
      upload = rowdy_uploads(:failed_upload)
      render_inline(UploadItemComponent.new(upload: upload))

      assert_selector '.rowdy-upload-error'
      assert_selector '.rowdy-error-message'
      assert_text upload.error_message
    end

    test "failed upload does not show download button" do
      upload = rowdy_uploads(:failed_upload)
      render_inline(UploadItemComponent.new(upload: upload))

      assert_no_selector '.rowdy-download-button'
    end

    # Test: Status labels with I18n
    test "renders status label in English" do
      I18n.locale = :en
      upload = rowdy_uploads(:pending_upload)
      render_inline(UploadItemComponent.new(upload: upload))

      assert_selector '.rowdy-upload-status', text: "Pending"
    end

    test "renders status label in Spanish" do
      I18n.with_locale(:es) do
        upload = rowdy_uploads(:pending_upload)
        render_inline(UploadItemComponent.new(upload: upload))

        assert_selector '.rowdy-upload-status', text: "Pendiente"
      end
    end

    test "renders processing status label in English" do
      I18n.locale = :en
      upload = rowdy_uploads(:processing_upload)
      render_inline(UploadItemComponent.new(upload: upload))

      assert_selector '.rowdy-upload-status', text: "Processing"
    end

    test "renders completed status label in English" do
      I18n.locale = :en
      upload = rowdy_uploads(:completed_upload)
      render_inline(UploadItemComponent.new(upload: upload))

      assert_selector '.rowdy-upload-status', text: "Completed"
    end

    test "renders failed status label in English" do
      I18n.locale = :en
      upload = rowdy_uploads(:failed_upload)
      render_inline(UploadItemComponent.new(upload: upload))

      assert_selector '.rowdy-upload-status', text: "Failed"
    end

    # Test: Download link
    test "download link has correct path" do
      upload = rowdy_uploads(:completed_upload)
      component = UploadItemComponent.new(upload: upload)

      expected_path = Rowdy::Engine.routes.url_helpers.upload_path(upload)
      assert_equal expected_path, component.download_path
    end

    # Test: HTML structure
    test "has correct HTML structure" do
      upload = rowdy_uploads(:processing_upload)
      render_inline(UploadItemComponent.new(upload: upload))

      assert_selector '.rowdy-upload-item' do
        assert_selector '.rowdy-upload-info' do
          assert_selector '.rowdy-upload-filename'
          assert_selector '.rowdy-upload-status'
        end
        assert_selector '.rowdy-upload-progress-bar' do
          assert_selector 'progress'
          assert_selector '.rowdy-upload-progress-text'
        end
      end
    end

    # Test: Data attributes
    test "sets correct upload ID in data attribute" do
      upload = rowdy_uploads(:pending_upload)
      render_inline(UploadItemComponent.new(upload: upload))

      assert_selector "[data-upload-id='#{upload.id}']"
    end

    test "sets correct status in data attribute" do
      upload = rowdy_uploads(:processing_upload)
      render_inline(UploadItemComponent.new(upload: upload))

      assert_selector '[data-upload-status="processing"]'
    end

    # Test: CSS classes
    test "has rowdy-upload-item class" do
      upload = rowdy_uploads(:pending_upload)
      render_inline(UploadItemComponent.new(upload: upload))

      assert_selector '.rowdy-upload-item'
    end

    test "has unique ID for each upload" do
      upload = rowdy_uploads(:pending_upload)
      render_inline(UploadItemComponent.new(upload: upload))

      assert_selector "#upload-#{upload.id}"
    end

    # Test: Edge cases
    test "handles upload with 0% progress" do
      upload = rowdy_uploads(:processing_upload)
      upload.update!(progress: 0)
      render_inline(UploadItemComponent.new(upload: upload))

      assert_selector 'progress[value="0"]'
      assert_text "0%"
    end

    test "handles upload with 100% progress" do
      upload = rowdy_uploads(:processing_upload)
      upload.update!(progress: 100)
      render_inline(UploadItemComponent.new(upload: upload))

      assert_selector 'progress[value="100"]'
      assert_text "100%"
    end

    test "handles upload with nil error message" do
      upload = rowdy_uploads(:completed_upload)
      upload.update!(error_message: nil)
      render_inline(UploadItemComponent.new(upload: upload))

      assert_no_selector '.rowdy-upload-error'
    end
  end
end
