require "rails_helper"

module Rowdy
  RSpec.describe DynamicSchemaBuilder do
    after { described_class.clear_cache }

    def create_definition(name: "test_schema", label: "Test Schema", columns_config: nil)
      columns_config ||= [ { "name" => "title", "type" => "string" } ]
      SchemaDefinition.create!(name: name, label: label, columns_config: columns_config)
    end

    describe ".build" do
      it "returns a Schema subclass" do
        sd = create_definition
        schema = described_class.build(sd)

        expect(schema.superclass).to eq(Rowdy::Schema)
      end

      it "sets schema_name from the definition name" do
        sd = create_definition(name: "order_import")
        schema = described_class.build(sd)

        expect(schema.schema_name).to eq("order_import")
      end

      it "sets schema_label from the definition label" do
        sd = create_definition(label: "Order Import")
        schema = described_class.build(sd)

        expect(schema.schema_label).to eq("Order Import")
      end

      it "marks the schema as dynamic" do
        sd = create_definition
        schema = described_class.build(sd)

        expect(schema.dynamic?).to be true
      end

      it "exposes the schema_definition_id" do
        sd = create_definition
        schema = described_class.build(sd)

        expect(schema.schema_definition_id).to eq(sd.id)
      end

      it "builds columns from columns_config" do
        sd = create_definition(columns_config: [
          { "name" => "sku", "type" => "string" },
          { "name" => "price", "type" => "decimal" }
        ])
        schema = described_class.build(sd)

        expect(schema.column_names).to eq(%i[sku price])
      end

      it "sets column types correctly" do
        sd = create_definition(columns_config: [
          { "name" => "count", "type" => "integer" }
        ])
        schema = described_class.build(sd)

        expect(schema.columns.first.type).to eq(:integer)
      end
    end

    describe "option coercion" do
      it "coerces required to boolean true" do
        sd = create_definition(columns_config: [
          { "name" => "sku", "type" => "string", "required" => "1" }
        ])
        schema = described_class.build(sd)

        expect(schema.columns.first).to be_required
      end

      it "coerces required false-like values to false" do
        sd = create_definition(columns_config: [
          { "name" => "sku", "type" => "string", "required" => "0" }
        ])
        schema = described_class.build(sd)

        expect(schema.columns.first).not_to be_required
      end

      it "coerces unique to boolean true" do
        sd = create_definition(columns_config: [
          { "name" => "sku", "type" => "string", "unique" => "1" }
        ])
        schema = described_class.build(sd)

        expect(schema.columns.first).to be_unique
      end

      it "coerces unique false-like values to false" do
        sd = create_definition(columns_config: [
          { "name" => "sku", "type" => "string", "unique" => "0" }
        ])
        schema = described_class.build(sd)

        expect(schema.columns.first).not_to be_unique
      end

      it "wraps inclusion into an array" do
        sd = create_definition(columns_config: [
          { "name" => "category", "type" => "string", "inclusion" => "electronics,clothing" }
        ])
        schema = described_class.build(sd)

        expect(schema.columns.first.inclusion).to eq([ "electronics,clothing" ])
      end

      it "preserves inclusion when already an array" do
        sd = create_definition(columns_config: [
          { "name" => "category", "type" => "string", "inclusion" => %w[electronics clothing] }
        ])
        schema = described_class.build(sd)

        expect(schema.columns.first.inclusion).to eq(%w[electronics clothing])
      end

      it "passes max_length through" do
        sd = create_definition(columns_config: [
          { "name" => "sku", "type" => "string", "max_length" => 10 }
        ])
        schema = described_class.build(sd)

        expect(schema.columns.first.max_length).to eq(10)
      end

      it "passes greater_than through" do
        sd = create_definition(columns_config: [
          { "name" => "price", "type" => "decimal", "greater_than" => 0 }
        ])
        schema = described_class.build(sd)

        expect(schema.columns.first.greater_than).to eq(0)
      end

      it "ignores unknown keys in columns_config" do
        sd = create_definition(columns_config: [
          { "name" => "sku", "type" => "string", "unknown_opt" => "something" }
        ])
        schema = described_class.build(sd)

        expect(schema.columns.first.name).to eq(:sku)
      end
    end

    describe ".all" do
      it "returns schemas for all definitions" do
        create_definition(name: "alpha_schema")
        create_definition(name: "beta_schema")

        schemas = described_class.all
        names = schemas.map(&:schema_name)

        expect(names).to contain_exactly("alpha_schema", "beta_schema")
      end

      it "returns an empty array when no definitions exist" do
        expect(described_class.all).to eq([])
      end
    end

    describe "caching" do
      it "returns cached schemas on subsequent calls" do
        create_definition(name: "cached_schema")
        first_call = described_class.all
        second_call = described_class.all

        expect(first_call.map(&:schema_name)).to eq(second_call.map(&:schema_name))
      end

      it "invalidates cache when a definition is updated" do
        sd = create_definition(name: "mutable_schema", label: "Original")
        original_schemas = described_class.all
        expect(original_schemas.first.schema_label).to eq("Original")

        sd.update!(label: "Updated")
        refreshed_schemas = described_class.all
        expect(refreshed_schemas.first.schema_label).to eq("Updated")
      end

      it "invalidates cache when a new definition is added" do
        create_definition(name: "first_schema")
        expect(described_class.all.size).to eq(1)

        create_definition(name: "second_schema")
        expect(described_class.all.size).to eq(2)
      end

      it "invalidates cache when a definition is destroyed" do
        sd = create_definition(name: "doomed_schema")
        expect(described_class.all.size).to eq(1)

        sd.destroy!
        expect(described_class.all.size).to eq(0)
      end
    end

    describe ".clear_cache" do
      it "forces a reload on the next call to .all" do
        create_definition(name: "original")
        described_class.all

        SchemaDefinition.find_by(name: "original").update!(label: "Changed")
        described_class.clear_cache

        expect(described_class.all.first.schema_label).to eq("Changed")
      end
    end
  end
end
