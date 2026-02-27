require "rails_helper"

module Rowdy
  RSpec.describe TypeCoercer do
    describe ".call" do
      context "string" do
        it "coerces to string" do
          expect(described_class.call("hello", :string)).to eq("hello")
        end

        it "coerces integer to string" do
          expect(described_class.call(42, :string)).to eq("42")
        end

        it "returns nil for nil" do
          expect(described_class.call(nil, :string)).to be_nil
        end

        it "returns nil for blank string" do
          expect(described_class.call("  ", :string)).to be_nil
        end
      end

      context "integer" do
        it "coerces string to integer" do
          expect(described_class.call("42", :integer)).to eq(42)
        end

        it "returns nil for non-numeric string" do
          expect(described_class.call("abc", :integer)).to be_nil
        end

        it "returns nil for nil" do
          expect(described_class.call(nil, :integer)).to be_nil
        end
      end

      context "float" do
        it "coerces string to float" do
          expect(described_class.call("3.14", :float)).to be_within(0.001).of(3.14)
        end

        it "returns nil for non-numeric string" do
          expect(described_class.call("abc", :float)).to be_nil
        end
      end

      context "decimal" do
        it "coerces string to BigDecimal" do
          result = described_class.call("9.99", :decimal)
          expect(result).to be_a(BigDecimal)
          expect(result).to eq(BigDecimal("9.99"))
        end
      end

      context "boolean" do
        %w[true 1 yes si sí].each do |truthy|
          it "coerces '#{truthy}' to true" do
            expect(described_class.call(truthy, :boolean)).to be(true)
          end
        end

        %w[false 0 no].each do |falsy|
          it "coerces '#{falsy}' to false" do
            expect(described_class.call(falsy, :boolean)).to be(false)
          end
        end

        it "returns nil for unrecognized value" do
          expect(described_class.call("maybe", :boolean)).to be_nil
        end
      end

      context "date" do
        it "coerces ISO date string to Date" do
          expect(described_class.call("2024-01-15", :date)).to eq(Date.new(2024, 1, 15))
        end

        it "returns Date unchanged if already a Date" do
          date = Date.today
          expect(described_class.call(date, :date)).to eq(date)
        end

        it "returns nil for invalid date string" do
          expect(described_class.call("not-a-date", :date)).to be_nil
        end
      end

      context "unknown type" do
        it "returns nil (ArgumentError rescued internally)" do
          expect(described_class.call("value", :unknown)).to be_nil
        end
      end
    end

    describe ".coercible?" do
      it "returns true for valid integer string" do
        expect(described_class.coercible?("42", :integer)).to be(true)
      end

      it "returns false for invalid integer string" do
        expect(described_class.coercible?("abc", :integer)).to be(false)
      end

      it "returns true for nil (treated as blank)" do
        expect(described_class.coercible?(nil, :integer)).to be(true)
      end

      it "returns true for blank string" do
        expect(described_class.coercible?("", :integer)).to be(true)
      end
    end
  end
end
