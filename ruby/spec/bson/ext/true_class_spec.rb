require "spec_helper"

describe BSON::Ext::TrueClass do

  describe "#bson_type" do

    it "returns the BSON_TYPE" do
      expect(true.bson_type).to eq(FalseClass::BSON_TYPE)
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
