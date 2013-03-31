# encoding: utf-8
require "spec_helper"

describe TrueClass do

  describe "#to_bson" do

    let(:obj)  { true }
    let(:bson) { 1.chr }
    let(:type) { 8.chr }

    it_behaves_like "a bson element"
    it_behaves_like "a serializable bson element"
  end
end
