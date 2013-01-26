require 'spec_helper'

module BSON
  describe Float do
    let(:type)  { "\x01" }
    let(:obj)   { 1.2 }
    let(:value) { "333333\xF3?" }
    
    it_behaves_like 'a bson element'
  end
end