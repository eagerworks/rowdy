require "test_helper"

module Rowdy
  class DropzoneComponentTest < ActiveSupport::TestCase
    # Test: Default rendering
    test "renders with default English label" do
      I18n.locale = :en
      render_inline(DropzoneComponent.new)

      assert_text "Drag XLSX files here"
    end

    test "renders with Spanish label when locale is Spanish" do
      I18n.with_locale(:es) do
        render_inline(DropzoneComponent.new)

        assert_text "Arrastrá archivos XLSX aquí"
      end
    end

    # Test: Custom label
    test "renders with custom label when provided" do
      render_inline(DropzoneComponent.new(label: "Drop your files here"))

      assert_text "Drop your files here"
      assert_no_text "Drag XLSX files here"
    end

    # Test: Data attributes and Stimulus
    test "renders with correct Stimulus controller" do
      render_inline(DropzoneComponent.new)

      assert_selector 'div[data-controller="rowdy-dropzone"]'
    end

    test "renders with dropzone target" do
      render_inline(DropzoneComponent.new)

      assert_selector 'div[data-rowdy-dropzone-target="dropzone"]'
    end

    test "renders with correct data actions for drag and drop" do
      render_inline(DropzoneComponent.new)

      assert_selector 'div[data-action*="dragover->rowdy-dropzone#handleDragOver"]'
      assert_selector 'div[data-action*="dragleave->rowdy-dropzone#handleDragLeave"]'
      assert_selector 'div[data-action*="drop->rowdy-dropzone#handleDrop"]'
      assert_selector 'div[data-action*="click->rowdy-dropzone#openFilePicker"]'
    end

    # Test: File input
    test "renders hidden file input with correct accept attribute" do
      render_inline(DropzoneComponent.new)

      assert_selector 'input[type="file"][accept=".xlsx,.xls"]', visible: :hidden
    end

    test "renders file input with custom accept attribute" do
      render_inline(DropzoneComponent.new(accept: ".csv,.xlsx"))

      assert_selector 'input[type="file"][accept=".csv,.xlsx"]', visible: :hidden
    end

    test "renders file input with change action" do
      render_inline(DropzoneComponent.new)

      assert_selector 'input[data-action="change->rowdy-dropzone#handleFileSelect"]', visible: :hidden
    end

    # Test: Multiple attribute
    test "renders file input with multiple attribute by default" do
      render_inline(DropzoneComponent.new)

      assert_selector 'input[type="file"][multiple]', visible: :hidden
    end

    test "renders file input without multiple when disabled" do
      render_inline(DropzoneComponent.new(multiple: false))

      assert_no_selector 'input[type="file"][multiple]', visible: :hidden
      assert_selector 'input[type="file"]', visible: :hidden
    end

    # Test: URL configuration
    test "uses engine routes for default URL" do
      component = DropzoneComponent.new

      assert_equal Rowdy::Engine.routes.url_helpers.uploads_path,
                   component.dropzone_url
    end

    test "uses custom URL when provided" do
      component = DropzoneComponent.new(url: "/custom/upload")

      assert_equal "/custom/upload", component.dropzone_url
    end

    test "renders with custom URL in data attribute" do
      render_inline(DropzoneComponent.new(url: "/custom/path"))

      assert_selector 'div[data-rowdy-dropzone-url-value="/custom/path"]'
    end

    # Test: CSS classes
    test "renders with rowdy-dropzone-area class" do
      render_inline(DropzoneComponent.new)

      assert_selector '.rowdy-dropzone-area'
    end

    test "renders file list target" do
      render_inline(DropzoneComponent.new)

      assert_selector 'div[data-rowdy-dropzone-target="fileList"]'
    end

    test "renders upload progress target" do
      render_inline(DropzoneComponent.new)

      assert_selector 'div[data-rowdy-dropzone-target="uploadProgress"]'
    end

    # Test: Custom HTML options
    test "accepts custom HTML options" do
      render_inline(DropzoneComponent.new(class: "custom-class", id: "custom-id"))

      assert_selector '#custom-id.custom-class[data-controller="rowdy-dropzone"]'
    end

    # Test: Component structure
    test "has correct nested structure" do
      render_inline(DropzoneComponent.new)

      # Outer container with Stimulus controller
      assert_selector 'div[data-controller="rowdy-dropzone"]' do
        # Dropzone area inside
        assert_selector '.rowdy-dropzone-area'
        # File input inside
        assert_selector 'input[type="file"]', visible: :hidden
        # File list container
        assert_selector '.rowdy-file-list'
        # Progress container
        assert_selector '.rowdy-upload-progress'
      end
    end
  end
end
