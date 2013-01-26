require 'spec_helper'

module BSON
  describe FalseClass do
    let(:type) { "\x08" }
    let(:obj)  { false }
    let(:value) { "\x00" }

    it_behaves_like "a bson element"
  end
end