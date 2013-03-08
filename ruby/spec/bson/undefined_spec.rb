# encoding: utf-8
require "spec_helper"

describe BSON::Undefined do
  let(:type) { 6.chr }
  let(:obj)  { described_class.new }
  let(:bson) { BSON::NO_VALUE }

  it_behaves_like "a bson element"
  it_behaves_like "a serializable bson element"
  it_behaves_like "a deserializable bson element"
end
