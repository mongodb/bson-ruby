require "spec_helper"

describe BSON::Binary do

  describe "::BSON_TYPE" do

    it "returns 0x05" do
      expect(BSON::Binary::BSON_TYPE).to eq(5.chr)
    end
  end

  describe "#bson_type" do

    let(:code) do
      described_class.new
    end

    it "returns 0x0D" do
      expect(code.bson_type).to eq(BSON::Binary::BSON_TYPE)
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
