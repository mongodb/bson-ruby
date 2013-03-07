# encoding: utf-8
require "spec_helper"

describe BSON do

  describe "::BINARY" do

    it "returns BINARY" do
      expect(BSON::BINARY).to eq("BINARY")
    end
  end

  describe "::NO_VAUE" do

    it "returns an empty string" do
      expect(BSON::NO_VALUE).to be_empty
    end
  end

  describe "::NULL_BYTE" do

    it "returns the char 0x00" do
      expect(BSON::NULL_BYTE).to eq(0.chr)
    end
  end

  describe "::UTF8" do

    it "returns UTF-8" do
      expect(BSON::UTF8).to eq("UTF-8")
    end
  end
end
