# encoding: utf-8
require "spec_helper"

describe BSON::Undefined do

  describe "::BSON_TYPE" do

    it "returns 0x06" do
      expect(BSON::Undefined::BSON_TYPE).to eq(6.chr)
    end
  end

  describe "#to_bson" do

    let(:encoded) do
      described_class.new.to_bson
    end

    it "returns the encoded string" do
      expect(encoded).to eq(BSON::NO_VALUE)
    end

    it_behaves_like "a binary encoded string"
  end
end
