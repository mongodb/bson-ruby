# encoding: utf-8
require "spec_helper"

describe BSON::Timestamp do

  describe "#==" do

    let(:timestamp) do
      described_class.new(1, 10)
    end

    context "when the objects are equal" do

      let(:other) do
        described_class.new(1, 10)
      end

      it "returns true" do
        expect(timestamp).to eq(other)
      end
    end

    context "when the objects are not equal" do

      let(:other) do
        described_class.new(1, 15)
      end

      it "returns false" do
        expect(timestamp).to_not eq(other)
      end
    end

    context "when the other object is not a timestamp" do

      it "returns false" do
        expect(timestamp).to_not eq("test")
      end
    end
  end

  describe "::BSON_TYPE" do

    it "returns 0x11" do
      expect(BSON::Timestamp::BSON_TYPE).to eq(17.chr)
    end
  end

  describe "#bson_type" do

    let(:timestamp) do
      described_class.new(1, 10)
    end

    it "returns the bson type" do
      expect(timestamp.bson_type).to eq(BSON::Timestamp::BSON_TYPE)
    end
  end

  describe "#to_bson" do

    let(:timestamp) do
      described_class.new(1, 10)
    end

    let(:packed_timestamp) do
      [ 1, 10 ].pack("l2")
    end

    it "returns the encoded timestamp" do
      expect(timestamp.to_bson).to eq(packed_timestamp)
    end
  end

  context "when the class is loaded" do

    let(:registered) do
      BSON::Registry.get(BSON::Timestamp::BSON_TYPE)
    end

    it "registers the type" do
      expect(registered).to eq(described_class)
    end
  end
end
