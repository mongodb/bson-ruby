# encoding: utf-8
require "spec_helper"

describe Hash do
  let(:type) { 3.chr }

  it_behaves_like "a bson element"

  context "when the hash is a single level" do
    let(:obj)  { { "key" => "value" } }
    let(:bson) {
      "#{20.to_bson}#{String::BSON_TYPE}key#{BSON::NULL_BYTE}" +
      "#{6.to_bson}value#{BSON::NULL_BYTE}#{BSON::NULL_BYTE}"
    }

    it_behaves_like "a serializable bson element"
    pending do
      it_behaves_like "a deserializable bson element"
    end
  end

  context "when the hash is embedded" do
    let(:obj)  { { "field" => { "key" => "value" } } }
    let(:bson) {
      "#{32.to_bson}#{Hash::BSON_TYPE}field#{BSON::NULL_BYTE}" +
      "#{20.to_bson}#{String::BSON_TYPE}key#{BSON::NULL_BYTE}" +
      "#{6.to_bson}value#{BSON::NULL_BYTE}#{BSON::NULL_BYTE}#{BSON::NULL_BYTE}"
    }

    it_behaves_like "a serializable bson element"
    pending do
      it_behaves_like "a deserializable bson element"
    end
  end
end
