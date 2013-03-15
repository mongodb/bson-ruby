# encoding: utf-8
require "spec_helper"

describe NilClass do

  describe "#to_bson/#from_bson" do

    let(:type) { 10.chr }
    let(:obj)  { nil }
    let(:bson) { BSON::NO_VALUE }

    it_behaves_like "a bson element"
    it_behaves_like "a serializable bson element"
    it_behaves_like "a deserializable bson element"
  end
end
