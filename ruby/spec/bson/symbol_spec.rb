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
end
