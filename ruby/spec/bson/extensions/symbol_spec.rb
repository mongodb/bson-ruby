require 'spec_helper'

module BSON
  describe Symbol do
    let(:symbol) { :test }

    context 'when serialized' do
      it 'should have BSON type \x0E' do
        symbol.bson_type.should == "\x0E"
      end
    end
  end
end