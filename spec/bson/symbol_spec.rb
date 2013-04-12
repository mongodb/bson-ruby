# encoding: utf-8
require "spec_helper"

describe Symbol do

  describe "#to_bson/#from_bson" do

    let(:type) { 14.chr }
    let(:obj)  { :test }
    let(:bson) { "#{5.to_bson}test#{BSON::NULL_BYTE}" }

    it_behaves_like "a bson element"
    it_behaves_like "a serializable bson element"
    it_behaves_like "a deserializable bson element"

  end

  describe "#to_bson_cstring" do

    let(:symbol) { :test }
    let(:encoded) { symbol.to_s + BSON::NULL_BYTE }
    let(:previous_content) { 'previous_content'.force_encoding(BSON::BINARY) }

    it "returns the encoded string" do
      expect(symbol.to_bson_cstring).to eq(encoded)
    end

    it "appends to optional previous content" do
      expect(symbol.to_bson_cstring(previous_content)).to eq(previous_content << encoded)
    end
  end
end
