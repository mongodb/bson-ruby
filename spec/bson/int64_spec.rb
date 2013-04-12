# encoding: utf-8
require "spec_helper"

describe BSON::Int64 do

  describe "#from_bson" do

    let(:type) { 18.chr }
    let(:obj)  { 12332423432242 }
    let(:bson) { [ obj ].pack(BSON::Int64::PACK) }

    it_behaves_like "a bson element"
    it_behaves_like "a deserializable bson element"
  end
end
