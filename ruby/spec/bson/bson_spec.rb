require 'spec_helper'

module BSON
  shared_examples_for 'a bson element' do
    it 'has correct bson type' do
      obj.bson_type.should == type
    end

    it 'serializes to bson' do
      obj.bson_value.should == value
    end

    it 'deserializes from bson' do
      io = StringIO.new(value)
      Types::MAP[obj.bson_type.ord].from_bson(io).should == obj
    end
  end

  describe Float do
    it_behaves_like 'a bson element' do
      let(:obj)   { 1.2 }
      let(:type)  { "\x01" }
      let(:value) { "333333\xF3?" }
    end
  end

  describe String do
    it_behaves_like 'a bson element' do
      let(:obj)   { "string" }
      let(:type)  { "\x02" }
      let(:value) { "\a\x00\x00\x00string\x00" }
    end
  end

  describe Hash do
    it_behaves_like 'a bson element' do
      let(:obj)   { { :a => 1 } }
      let(:type)  { "\x03" }
      let(:value) { "\f\x00\x00\x00\x10a\x00\x01\x00\x00\x00\x00" }
    end
  end

  describe Array do
    it_behaves_like 'a bson element' do
      let(:obj)   { ['a'] }
      let(:type)  { "\x04" }
      let(:value) { "\x0E\x00\x00\x00\x020\x00\x02\x00\x00\x00a\x00\x00" }
    end
  end

  describe Binary do
    it_behaves_like 'a bson element' do
      let(:obj)   { Binary.new("a") }
      let(:type)  { "\x05" }
      let(:value) { "\x01\x00\x00\x00\x00a" }
    end
  end

  describe Undefined do
    it_behaves_like 'a bson element' do
      let(:obj)   { Undefined }
      let(:type)  { "\x06" }
      let(:value) { "" }
    end
  end

  describe ObjectId do
    it_behaves_like 'a bson element' do
      let(:obj)   { ObjectId.new("a") }
      let(:type)  { "\x07" }
      let(:value) { "\x01\x00\x00\x00\x00a" }
    end
  end

  describe FalseClass do
    it_behaves_like "a bson element" do
      let(:obj)   { false }
      let(:type)  { "\x08" }
      let(:value) { "\x00" }
    end
  end

  describe TrueClass do
    it_behaves_like 'a bson element' do
      let(:obj)   { true }
      let(:type)  { "\x08" }
      let(:value) { "\x01" }
    end
  end

  describe Time do
    it_behaves_like 'a bson element' do
      let(:obj)   { ObjectId.new("a") }
      let(:type)  { "\x07" }
      let(:value) { "\x01\x00\x00\x00\x00a" }
    end
  end

  describe nil do
    it_behaves_like 'a bson element' do
      let(:obj)   { ObjectId.new("a") }
      let(:type)  { "\x07" }
      let(:value) { "\x01\x00\x00\x00\x00a" }
    end
  end

  describe Regexp do
    it_behaves_like 'a bson element' do
      let(:obj)   { ObjectId.new("a") }
      let(:type)  { "\x07" }
      let(:value) { "\x01\x00\x00\x00\x00a" }
    end
  end

  describe DBPointer do
    it_behaves_like 'a bson element' do
      let(:obj)   { ObjectId.new("a") }
      let(:type)  { "\x07" }
      let(:value) { "\x01\x00\x00\x00\x00a" }
    end
  end

  describe Code do
    it_behaves_like 'a bson element' do
      let(:obj)   { ObjectId.new("a") }
      let(:type)  { "\x07" }
      let(:value) { "\x01\x00\x00\x00\x00a" }
    end
  end

  describe Symbol do
    it_behaves_like 'a bson element' do
      let(:obj)   { ObjectId.new("a") }
      let(:type)  { "\x07" }
      let(:value) { "\x01\x00\x00\x00\x00a" }
    end
  end

  describe Int32 do
    it_behaves_like 'a bson element' do
      let(:obj)   { ObjectId.new("a") }
      let(:type)  { "\x07" }
      let(:value) { "\x01\x00\x00\x00\x00a" }
    end
  end

  describe Timestamp do
    it_behaves_like 'a bson element' do
      let(:obj)   { ObjectId.new("a") }
      let(:type)  { "\x07" }
      let(:value) { "\x01\x00\x00\x00\x00a" }
    end
  end

  describe Int64 do
    it_behaves_like 'a bson element' do
      let(:obj)   { ObjectId.new("a") }
      let(:type)  { "\x07" }
      let(:value) { "\x01\x00\x00\x00\x00a" }
    end
  end

  describe MinKey do
    it_behaves_like 'a bson element' do
      let(:obj)   { MinKey }
      let(:type)  { "\xFF" }
      let(:value) { "" }
    end
  end

  describe MaxKey do
    it_behaves_like 'a bson element' do
      let(:obj)   { MaxKey }
      let(:type)  { "\x7F" }
      let(:value) { "" }
    end
  end
end