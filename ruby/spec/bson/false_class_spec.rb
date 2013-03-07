# encoding: utf-8
require "spec_helper"

describe FalseClass do
  let(:obj)  { false }
  let(:bson) { 0.chr }

  it_behaves_like "a serializable bson element"
end
