# encoding: utf-8
require "spec_helper"

describe BSON::Code do

  let(:type) { 13.chr }
  let(:obj)  { described_class.new("this.value = 5") }
  let(:bson) { "#{15.to_bson}this.value = 5#{BSON::NULL_BYTE}" }

  it_behaves_like "a bson element"
  it_behaves_like "a serializable bson element"
  it_behaves_like "a deserializable bson element"
end
