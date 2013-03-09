# encoding: utf-8
require "spec_helper"

describe BSON::Binary do

  describe "#as_json" do

    let(:object) do
      described_class.new("testing", :user)
    end

    it "returns the binary data plus type" do
      expect(object.as_json).to eq(
        { "$binary" => "testing", "$type" => :user }
      )
    end

    it_behaves_like "a JSON serializable object"
  end

  let(:type) { 5.chr }

  it_behaves_like "a bson element"

  context "when the type is :generic" do
    let(:obj)  { described_class.new("testing") }
    let(:bson) { "#{7.to_bson}#{0.chr}testing" }
    it_behaves_like "a serializable bson element"
    it_behaves_like "a deserializable bson element"
  end

  context "when the type is :function" do
    let(:obj)  { described_class.new("testing", :function) }
    let(:bson) { "#{7.to_bson}#{1.chr}testing" }
    it_behaves_like "a serializable bson element"
    it_behaves_like "a deserializable bson element"
  end

  describe "::BSON_TYPE" do

    context "when the type is :old" do
      let(:obj)  { described_class.new("testing", :old) }
      let(:bson) { "#{11.to_bson}#{2.chr}#{7.to_bson}testing" }
      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end

    context "when the type is :uuid_old" do
      let(:obj)  { described_class.new("testing", :uuid_old) }
      let(:bson) { "#{7.to_bson}#{3.chr}testing" }
      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end

    context "when the type is :uuid" do
      let(:obj)  { described_class.new("testing", :uuid) }
      let(:bson) { "#{7.to_bson}#{4.chr}testing" }
      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end

    context "when the type is :md5" do
      let(:obj)  { described_class.new("testing", :md5) }
      let(:bson) { "#{7.to_bson}#{5.chr}testing" }
      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end

    context "when the type is :user" do
      let(:obj)  { described_class.new("testing", :user) }
      let(:bson) { "#{7.to_bson}#{128.chr}testing" }
      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end
  end
end
