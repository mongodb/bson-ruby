require "spec_helper"

describe BSON::ObjectId do

  describe "::BSON_TYPE" do

    it "returns 0x07" do
      expect(BSON::ObjectId::BSON_TYPE).to eq(7.chr)
    end
  end

  describe "#bson_type" do

    let(:code) do
      described_class.new
    end

    it "returns 0x0D" do
      expect(code.bson_type).to eq(BSON::ObjectId::BSON_TYPE)
    end
  end

  pending "#to_bson"

  context "when the class is loaded" do

    let(:registered) do
      BSON::Registry.get(BSON::ObjectId::BSON_TYPE)
    end

    it "registers the type" do
      expect(registered).to eq(described_class)
    end
  end
end
