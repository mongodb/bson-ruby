# encoding: utf-8
require "spec_helper"

describe BSON::NilClass do

  describe "::BSON_TYPE" do

    it "returns 0x0A" do
      expect(NilClass::BSON_TYPE).to eq(10.chr)
    end
  end

  describe "#bson_type" do

    it "returns the BSON_TYPE" do
      expect(nil.bson_type).to eq(NilClass::BSON_TYPE)
    end
  end

  describe "#to_bson" do

    let(:encoded) do
      nil.to_bson
    end

    it "returns an empty string" do
      expect(encoded).to be_empty
    end
  end

  context "when the class is loaded" do

    let(:registered) do
      BSON::Registry.get(NilClass::BSON_TYPE)
    end

    it "registers the type" do
      expect(registered).to eq(NilClass)
    end
  end
end
