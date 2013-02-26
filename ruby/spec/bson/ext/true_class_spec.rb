require "spec_helper"

describe BSON::Ext::TrueClass do

  describe "::BSON_TYPE" do

    it "returns 0x08" do
      expect(TrueClass::BSON_TYPE).to eq(8.chr)
    end
  end

  describe "#bson_type" do

    it "returns the BSON_TYPE" do
      expect(true.bson_type).to eq(TrueClass::BSON_TYPE)
    end
  end

  describe "#to_bson" do

    let(:encoded) do
      true.to_bson
    end

    it "returns the encoded string" do
      expect(encoded).to eq(1.chr)
    end
  end
end
