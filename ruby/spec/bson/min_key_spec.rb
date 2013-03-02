# encoding: utf-8
require "spec_helper"

describe BSON::MinKey do

  describe "#==" do

    let(:max_key) do
      described_class.new
    end

    context "when the objects are equal" do

      let(:other) do
        described_class.new
      end

      it "returns true" do
        expect(max_key).to eq(other)
      end
    end

    context "when the other object is not a max_key" do

      it "returns false" do
        expect(max_key).to_not eq("test")
      end
    end
  end

  describe "#>" do

    let(:min_key) do
      described_class.new
    end

    it "always returns false" do
      expect(min_key > Integer::MIN_64BIT).to be_false
    end
  end

  describe "#<" do

    let(:min_key) do
      described_class.new
    end

    it "always returns true" do
      expect(min_key < Integer::MIN_64BIT).to be_true
    end
  end

  describe "::BSON_TYPE" do

    it "returns 0xFF" do
      expect(BSON::MinKey::BSON_TYPE).to eq(255.chr)
    end
  end

  describe "#bson_type" do

    let(:min_key) do
      described_class.new
    end

    it "returns 0xFF" do
      expect(min_key.bson_type).to eq(BSON::MinKey::BSON_TYPE)
    end
  end

  describe "#to_bson" do

    let(:min_key) do
      described_class.new
    end

    it "returns an empty string" do
      expect(min_key.to_bson).to be_empty
    end
  end

  context "when the class is loaded" do

    let(:registered) do
      BSON::Registry.get(BSON::MinKey::BSON_TYPE)
    end

    it "registers the type" do
      expect(registered).to eq(described_class)
    end
  end
end
