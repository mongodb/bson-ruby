# encoding: utf-8
require "spec_helper"

describe BSON do
  describe "::INT32_PACK" do
    it "returns l" do
      expect(BSON::INT32_PACK).to eq("l")
    end
  end

  describe "::INT64_PACK" do
    it "returns q" do
      expect(BSON::INT64_PACK).to eq("q")
    end
  end
end