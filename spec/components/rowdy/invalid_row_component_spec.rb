require "rails_helper"

module Rowdy
  RSpec.describe InvalidRowComponent, type: :component do
    let(:import_error) do
      build_stubbed(:rowdy_import_error,
        row_number: 5,
        row_data: { "sku" => "BAD-VALUE" },
        column_errors: { "sku" => [ "is required" ] })
    end

    subject(:rendered) do
      render_inline(described_class.new(
        import_error: import_error,
        column: "sku",
        messages: [ "is required" ]
      ))
    end

    it "renders the row number" do
      expect(rendered.text).to include("5")
    end

    it "renders the column name" do
      expect(rendered.text).to include("sku")
    end

    it "renders the error message" do
      expect(rendered.text).to include("is required")
    end

    it "renders an input with the current value" do
      expect(rendered.css("input[value='BAD-VALUE']")).to be_present
    end

    it "renders the input with data-original-value set to the current value" do
      expect(rendered.css("input[data-original-value='BAD-VALUE']")).to be_present
    end

    it "renders the input with the correct name for bulk form submission" do
      expected_name = "corrections[#{import_error.id}][sku]"
      expect(rendered.css("input[name='#{expected_name}']")).to be_present
    end
  end
end
