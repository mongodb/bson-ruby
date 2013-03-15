# encoding: utf-8
require "spec_helper"

describe BSON::CodeWithScope do

  describe "#as_json" do

    let(:object) do
      described_class.new("this.value = val", :val => "test")
    end

    it "returns the binary data plus type" do
      expect(object.as_json).to eq(
        { "$code" => "this.value = val", "$scope" => { :val => "test" }}
      )
    end

    it_behaves_like "a JSON serializable object"
  end

  describe "#to_bson/#from_bson" do

    let(:type) { 15.chr }
    let(:code) { "this.value == name" }
    let(:scope) do
      { :name => "test" }
    end
    let(:obj) { described_class.new(code, scope) }
    let(:bson) do
      "#{48.to_bson}#{(code.length + 1).to_bson}#{code}#{BSON::NULL_BYTE}" +
      "#{scope.to_bson}#{BSON::NULL_BYTE}"
    end

    it_behaves_like "a bson element"
    it_behaves_like "a serializable bson element"
    pending "a deserializable bson element"
  end
end
