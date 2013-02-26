require "spec_helper"

describe BSON::Ext::String do

  describe "::BSON_TYPE" do

    it "returns 0x02" do
      expect(String::BSON_TYPE).to eq(2.chr)
    end
  end

  describe "#bson_type" do

    it "returns the BSON_TYPE" do
      expect("test".bson_type).to eq(String::BSON_TYPE)
    end
  end

  describe "#to_bson" do

    let(:string) do
      "test"
    end

    let(:encoded) do
      string.to_bson
    end

    it "returns the encoded string" do
      expect(encoded).to eq("\x05\x00\x00\x00test\x00")
    end
  end

  describe "#to_bson_cstring" do

    let(:string) do
      "test"
    end

    let(:encoded) do
      string.to_bson_cstring
    end

    it "returns the encoded string" do
      expect(encoded).to eq("test\x00")
    end
  end
end
