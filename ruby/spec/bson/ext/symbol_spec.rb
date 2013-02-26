require "spec_helper"

describe BSON::Ext::Symbol do

  describe "::BSON_TYPE" do

    it "returns 0x0E" do
      expect(Symbol::BSON_TYPE).to eq(14.chr)
    end
  end

  describe "#bson_type" do

    it "returns the BSON_TYPE" do
      expect(:test.bson_type).to eq(Symbol::BSON_TYPE)
    end
  end

  describe "#to_bson" do

    let(:symbol) do
      :test
    end

    let(:encoded) do
      symbol.to_bson
    end

    it "returns the encoded symbol" do
      expect(encoded).to eq("#{5.to_bson}test#{BSON::NULL_BYTE}")
    end
  end

  describe "#to_bson_cstring" do

    let(:symbol) do
      :test
    end

    let(:encoded) do
      symbol.to_bson_cstring
    end

    it "returns the encoded symbol" do
      expect(encoded).to eq("test#{BSON::NULL_BYTE}")
    end
  end
end
