# encoding: utf-8
require "spec_helper"

describe Regexp do
  let(:type) { 11.chr }
  let(:obj)  { /test/ }

  it_behaves_like "a bson element"

  context "when the regexp has no options" do
    let(:obj)  { /\d+/ }
    let(:bson) { "#{obj.source}#{BSON::NULL_BYTE}#{BSON::NULL_BYTE}" }
    it_behaves_like "a serializable bson element"
    it_behaves_like "a deserializable bson element"
  end

  context "when the regexp has options" do
    context "when ignoring case" do
      let(:obj)  { /\W+/i }
      let(:bson) { "#{obj.source}#{BSON::NULL_BYTE}i#{BSON::NULL_BYTE}" }
      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end

    context "when matching multiline" do
      let(:obj)  { /\W+/m }
      let(:bson) { "#{obj.source}#{BSON::NULL_BYTE}ms#{BSON::NULL_BYTE}" }
      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end

    context "when matching extended" do
      let(:obj)  { /\W+/x }
      let(:bson) { "#{obj.source}#{BSON::NULL_BYTE}x#{BSON::NULL_BYTE}" }
      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end

    context "when all options are present" do
      let(:obj)  { /\W+/xim }
      let(:bson) { "#{obj.source}#{BSON::NULL_BYTE}imsx#{BSON::NULL_BYTE}" }
      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end
  end
end
