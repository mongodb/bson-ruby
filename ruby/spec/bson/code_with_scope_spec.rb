# encoding: utf-8
require "spec_helper"

module BSON
  describe CodeWithScope do
    let(:type)  { 15.chr }
    let(:code)  { "this.value == name" }
    let(:scope) { {:name => "test"} }
    let(:obj)   { described_class.new(code, scope) }
    let(:bson)  {
      "#{48.to_bson}#{(code.length + 1).to_bson}#{code}#{BSON::NULL_BYTE}" +
      "#{scope.to_bson}#{BSON::NULL_BYTE}"
    }

    it_behaves_like "a bson element"
    it_behaves_like "a serializable bson element"
    pending do
      it_behaves_like "a deserializable bson element"
    end
  end
end
