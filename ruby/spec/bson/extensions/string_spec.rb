require 'spec_helper'

module BSON
  describe String do
    let(:type)  { "\x02" }
    let(:obj)   { "string" }
    let(:value) { "\a\x00\x00\x00string\x00" }

    it_behaves_like 'a bson element'
  end
end