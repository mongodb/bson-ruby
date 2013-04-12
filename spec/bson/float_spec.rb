# encoding: utf-8
require "spec_helper"

describe Float do

  describe "#to_bson/#from_bson" do

    let(:type) { 1.chr }
    let(:obj)  { 1.2332 }
    let(:bson) { [ obj ].pack(Float::PACK) }

    it_behaves_like "a bson element"
    it_behaves_like "a serializable bson element"
    it_behaves_like "a deserializable bson element"
  end
end
