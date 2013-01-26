require 'spec_helper'

module BSON
  describe TrueClass do
    let(:type) { "\x08" }
    let(:obj)  { true }
    let(:value) { "\x01" }

    it_behaves_like "a bson element"
  end
end