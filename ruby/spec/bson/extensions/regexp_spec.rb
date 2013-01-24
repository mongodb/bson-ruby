require 'spec_helper'

module BSON
  describe Regexp do
    let(:regexp) { /a/ }

    context 'when serialized' do
      it 'should have BSON type \x0B' do
        regexp.bson_type.should == "\x0B"
      end
    end
  end
end