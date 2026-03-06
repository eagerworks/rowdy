require "rails_helper"

module Rowdy
  RSpec.describe JsonQueryHelpers do
    shared_context "with PostgreSQL adapter" do
      before { allow(described_class).to receive(:adapter_name).and_return("PostgreSQL") }
    end

    shared_context "with MySQL adapter" do
      before { allow(described_class).to receive(:adapter_name).and_return("Mysql2") }
    end

    shared_context "with unsupported adapter" do
      before do
        described_class.instance_variable_set(:@adapter_name, nil)
        allow(ActiveRecord::Base.connection).to receive(:adapter_name).and_return("SQLite3")
      end

      after do
        described_class.instance_variable_set(:@adapter_name, nil)
      end
    end

    describe ".extract" do
      context "with PostgreSQL" do
        include_context "with PostgreSQL adapter"

        it "uses jsonb arrow operator" do
          expect(described_class.extract("row_data", "category")).to eq("row_data->>'category'")
        end
      end

      context "with MySQL" do
        include_context "with MySQL adapter"

        it "uses JSON_UNQUOTE + JSON_EXTRACT" do
          expect(described_class.extract("row_data", "category")).to eq("JSON_UNQUOTE(JSON_EXTRACT(row_data, '$.category'))")
        end
      end

      context "with unsupported adapter" do
        include_context "with unsupported adapter"

        it "raises UnsupportedAdapterError" do
          expect { described_class.extract("row_data", "category") }
            .to raise_error(described_class::UnsupportedAdapterError, /SQLite/)
        end
      end
    end

    describe ".has_key_condition" do
      context "with PostgreSQL" do
        include_context "with PostgreSQL adapter"

        it "uses jsonb_exists function" do
          expect(described_class.has_key_condition("column_errors", "category"))
            .to eq([ "jsonb_exists(column_errors, ?)", "category" ])
        end
      end

      context "with MySQL" do
        include_context "with MySQL adapter"

        it "uses JSON_CONTAINS_PATH" do
          expect(described_class.has_key_condition("column_errors", "category"))
            .to eq([ "JSON_CONTAINS_PATH(column_errors, 'one', '$.category')" ])
        end
      end

      context "with unsupported adapter" do
        include_context "with unsupported adapter"

        it "raises UnsupportedAdapterError" do
          expect { described_class.has_key_condition("column_errors", "category") }
            .to raise_error(described_class::UnsupportedAdapterError)
        end
      end
    end

    describe ".empty_condition" do
      context "with PostgreSQL" do
        include_context "with PostgreSQL adapter"

        it "wraps jsonb extraction in TRIM + COALESCE" do
          expect(described_class.empty_condition("row_data", "category"))
            .to eq([ "TRIM(COALESCE(row_data->>'category', '')) = ''" ])
        end
      end

      context "with MySQL" do
        include_context "with MySQL adapter"

        it "wraps JSON_UNQUOTE extraction in TRIM + COALESCE" do
          expect(described_class.empty_condition("row_data", "category"))
            .to eq([ "TRIM(COALESCE(JSON_UNQUOTE(JSON_EXTRACT(row_data, '$.category')), '')) = ''" ])
        end
      end
    end

    describe ".exact_condition" do
      context "with case_sensitive: true (default)" do
        context "with PostgreSQL" do
          include_context "with PostgreSQL adapter"

          it "uses direct equality" do
            expect(described_class.exact_condition("row_data", "category", "ios", true))
              .to eq([ "row_data->>'category' = ?", "ios" ])
          end
        end

        context "with MySQL" do
          include_context "with MySQL adapter"

          it "uses binary collation for case sensitivity" do
            expect(described_class.exact_condition("row_data", "category", "ios", true))
              .to eq([ "JSON_UNQUOTE(JSON_EXTRACT(row_data, '$.category')) = ? COLLATE utf8mb4_bin", "ios" ])
          end
        end
      end

      context "with case_sensitive: false" do
        context "with PostgreSQL" do
          include_context "with PostgreSQL adapter"

          it "wraps both sides in LOWER" do
            expect(described_class.exact_condition("row_data", "category", "IOS", false))
              .to eq([ "LOWER(row_data->>'category') = LOWER(?)", "IOS" ])
          end
        end

        context "with MySQL" do
          include_context "with MySQL adapter"

          it "wraps both sides in LOWER" do
            expect(described_class.exact_condition("row_data", "category", "IOS", false))
              .to eq([ "LOWER(JSON_UNQUOTE(JSON_EXTRACT(row_data, '$.category'))) = LOWER(?)", "IOS" ])
          end
        end
      end
    end

    describe ".contains_condition" do
      context "with case_sensitive: true (default)" do
        context "with PostgreSQL" do
          include_context "with PostgreSQL adapter"

          it "uses LIKE without LOWER" do
            expect(described_class.contains_condition("row_data", "category", "io", true))
              .to eq([ "row_data->>'category' LIKE ?", "%io%" ])
          end
        end

        context "with MySQL" do
          include_context "with MySQL adapter"

          it "uses LIKE with binary collation" do
            expect(described_class.contains_condition("row_data", "category", "io", true))
              .to eq([ "JSON_UNQUOTE(JSON_EXTRACT(row_data, '$.category')) LIKE ? COLLATE utf8mb4_bin", "%io%" ])
          end
        end
      end

      context "with case_sensitive: false" do
        context "with PostgreSQL" do
          include_context "with PostgreSQL adapter"

          it "wraps both sides in LOWER" do
            expect(described_class.contains_condition("row_data", "category", "IO", false))
              .to eq([ "LOWER(row_data->>'category') LIKE LOWER(?)", "%IO%" ])
          end
        end

        context "with MySQL" do
          include_context "with MySQL adapter"

          it "wraps both sides in LOWER" do
            expect(described_class.contains_condition("row_data", "category", "IO", false))
              .to eq([ "LOWER(JSON_UNQUOTE(JSON_EXTRACT(row_data, '$.category'))) LIKE LOWER(?)", "%IO%" ])
          end
        end
      end

      context "when find_value contains LIKE special characters" do
        include_context "with PostgreSQL adapter"

        it "escapes % to prevent wildcard injection" do
          expect(described_class.contains_condition("row_data", "category", "50%off", true))
            .to eq([ "row_data->>'category' LIKE ?", "%50\\%off%" ])
        end

        it "escapes _ to prevent single-char wildcard injection" do
          expect(described_class.contains_condition("row_data", "category", "s_ze", true))
            .to eq([ "row_data->>'category' LIKE ?", "%s\\_ze%" ])
        end
      end
    end
  end
end
