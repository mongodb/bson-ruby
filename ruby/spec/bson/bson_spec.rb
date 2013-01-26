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
      let(:type)  { "\x01" }
      let(:obj)   { 1.2 }
      let(:value) { "333333\xF3?" }
    end
  end

  describe String do
    it_behaves_like 'a bson element' do
      let(:type)  { "\x02" }
      let(:obj)   { "string" }
      let(:value) { "\a\x00\x00\x00string\x00" }
    end
  end

  describe Hash do
    it_behaves_like 'a bson element' do
      let(:type)  { "\x03" } 
      let(:obj)   { { :a => 1 } }
      let(:value) { "\f\x00\x00\x00\x10a\x00\x01\x00\x00\x00\x00" }
    end
  end

  describe Array do
    it_behaves_like 'a bson element' do
      let(:type)  { "\x04" } 
      let(:obj)   { ['a'] }
      let(:value) { "\x0E\x00\x00\x00\x020\x00\x02\x00\x00\x00a\x00\x00" }
    end
  end

  describe Binary do
    it_behaves_like 'a bson element' do
      let(:type)  { "\x05" } 
      let(:obj)   { Binary.new("a") }
      let(:value) { "\x01\x00\x00\x00\x00a" }
    end
  end

  describe Undefined do
    it_behaves_like 'a bson element' do
      let(:type)  { "\x06" } 
      let(:obj)   { Undefined }
      let(:value) { "" }
    end
  end

  describe FalseClass do
    it_behaves_like "a bson element" do
      let(:type)  { "\x08" }
      let(:obj)   { false }
      let(:value) { "\x00" }
    end
  end

  describe TrueClass do
    it_behaves_like 'a bson element' do
      let(:type)  { "\x08" }
      let(:obj)   { true }
      let(:value) { "\x01" }
    end
  end
end