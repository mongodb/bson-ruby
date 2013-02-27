require "spec_helper"

describe BSON::Ext::Array do

  describe "::BSON_TYPE" do

    it "returns 0x04" do
      expect(Array::BSON_TYPE).to eq(4.chr)
    end
  end

  describe "#bson_type" do

    let(:array) do
      [ 1, 2, 3 ]
    end

    it "returns the BSON_TYPE" do
      expect(array.bson_type).to eq(Array::BSON_TYPE)
    end
  end

  pending "#to_bson"
end
