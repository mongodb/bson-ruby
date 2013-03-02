# encoding: utf-8
require "spec_helper"

describe BSON::Hash do

  describe "::BSON_TYPE" do

    it "returns 0x03" do
      expect(Hash::BSON_TYPE).to eq(3.chr)
    end
  end

  describe "#bson_type" do

    let(:hash) do
      { "field" => "value" }
    end

    it "returns the BSON_TYPE" do
      expect(hash.bson_type).to eq(Hash::BSON_TYPE)
    end
  end

  pending "#to_bson"

  context "when the class is loaded" do

    let(:registered) do
      BSON::Registry.get(Hash::BSON_TYPE)
    end

    it "registers the type" do
      expect(registered).to eq(Hash)
    end
  end
end
