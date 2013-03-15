# encoding: utf-8
require "spec_helper"

describe BSON::Boolean do

  describe "::BSON_TYPE" do

    it "returns 8" do
      expect(BSON::Boolean::BSON_TYPE).to eq(8.chr)
    end
  end

  describe "#from_bson" do

    let(:type) { 8.chr }

    it_behaves_like "a bson element"

    context "when the boolean is true" do

      let(:obj)  { true }
      let(:bson) { 1.chr }

      it_behaves_like "a deserializable bson element"
    end

    context "when the boolean is false" do

      let(:obj)  { false }
      let(:bson) { 0.chr }

      it_behaves_like "a deserializable bson element"
    end
  end
end
