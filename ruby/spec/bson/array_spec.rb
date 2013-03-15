# encoding: utf-8
require "spec_helper"

describe Array do

  let(:type) { 4.chr }
  let(:obj)  {[ "one", "two" ]}
  let(:bson) do
    { "0" => "one", "1" => "two" }.to_bson
  end

  it_behaves_like "a bson element"
  it_behaves_like "a serializable bson element"
  it_behaves_like "a deserializable bson element"
end
