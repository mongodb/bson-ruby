# encoding: utf-8
require "spec_helper"

describe FalseClass do

  describe "#to_bson" do

    let(:obj)  { false }
    let(:bson) { 0.chr }

    it_behaves_like "a serializable bson element"
  end
end
