# encoding: utf-8
require "spec_helper"

describe BSON::TrueClass do

  describe "::BSON_TYPE" do

    it "returns 0x08" do
      expect(TrueClass::BSON_TYPE).to eq(8.chr)
    end
  end

  describe "#to_bson" do

    let(:encoded) do
      true.to_bson
    end

    it "returns the encoded string" do
      expect(encoded).to eq(BSON::TrueClass::TRUE_BYTE)
    end
  end
end
