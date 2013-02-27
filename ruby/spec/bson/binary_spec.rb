require "spec_helper"

describe BSON::Binary do

  describe "::BSON_TYPE" do

    it "returns 0x05" do
      expect(BSON::Binary::BSON_TYPE).to eq(5.chr)
    end
  end

  describe "#bson_type" do

    let(:binary) do
      described_class.new(:md5, "test")
    end

    it "returns 0x0D" do
      expect(binary.bson_type).to eq(BSON::Binary::BSON_TYPE)
    end
  end

  describe "#initialize" do

    let(:data) do
      "testing"
    end

    let(:binary) do
      described_class.new(:md5, data)
    end

    it "sets the type" do
      expect(binary.type).to eq(:md5)
    end

    it "sets the data" do
      expect(binary.data).to eq(data)
    end
  end

  pending "#to_bson"

  context "when the class is loaded" do

    let(:registered) do
      BSON::Registry.get(BSON::Binary::BSON_TYPE)
    end

    it "registers the type" do
      expect(registered).to eq(described_class)
    end
  end
end
