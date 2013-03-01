require "spec_helper"

describe BSON::Ext::FalseClass do

  describe "::BSON_TYPE" do

    it "returns 0x08" do
      expect(FalseClass::BSON_TYPE).to eq(8.chr)
    end
  end

  describe "#to_bson" do

    let(:encoded) do
      false.to_bson
    end

    it "returns the encoded string" do
      expect(encoded).to eq(BSON::NULL_BYTE)
    end
  end
end
