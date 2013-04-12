# encoding: utf-8
require "spec_helper"

describe BSON::Int32 do

  describe "#from_bson" do

    let(:type) { 16.chr }
    let(:obj)  { 123 }
    let(:bson) { [ obj ].pack(BSON::Int32::PACK) }

    it_behaves_like "a bson element"
    it_behaves_like "a deserializable bson element"
  end
end
