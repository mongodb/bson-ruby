# encoding: utf-8
require "spec_helper"

describe BSON::Document do

  let(:type) { 3.chr }
  let(:obj)  { { :key => "value" } }
  let(:bson) {
    "#{20.to_bson}#{String::BSON_TYPE}key#{BSON::NULL_BYTE}" +
    "#{6.to_bson}value#{BSON::NULL_BYTE}#{BSON::NULL_BYTE}"
  }

  it_behaves_like "a bson element"
  it_behaves_like "a serializable bson element"
  pending do
    it_behaves_like "a deserializable bson element"
  end
end
