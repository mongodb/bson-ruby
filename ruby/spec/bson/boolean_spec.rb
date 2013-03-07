# encoding: utf-8
require "spec_helper"

module BSON
  describe Boolean do
    let(:type) { 8.chr }

    it_behaves_like "a bson element"
    
    context "true class" do
      let(:obj)  { true }
      let(:bson) { 1.chr }
      it_behaves_like "a deserializable bson element"
    end

    context "false class" do
      let(:obj)  { false }
      let(:bson) { 0.chr }
      it_behaves_like "a deserializable bson element"
    end
  end
end
