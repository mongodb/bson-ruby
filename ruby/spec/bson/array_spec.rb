# encoding: utf-8
require "spec_helper"

describe BSON::Array do

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

  describe "#to_bson" do

    let(:array) do
      [ "one", "two" ]
    end

    let(:encoded) do
      array.to_bson
    end

    let(:expected) do
      { "0" => "one", "1" => "two" }.to_bson
    end

    it "returns the encoded string" do
      expect(encoded).to eq(expected)
    end

    it_behaves_like "a binary encoded string"
  end

  context "when the class is loaded" do

    let(:registered) do
      BSON::Registry.get(Array::BSON_TYPE)
    end

    it "registers the type" do
      expect(registered).to eq(Array)
    end
  end
end
