require 'spec_helper'

module BSON
  describe TrueClass do
    context 'when serialized' do
      it 'should have BSON type \x08' do
        true.bson_type.should == "\x08"
      end

      it 'should have BSON value \x01' do
        true.bson_value.should == "\x01"
      end
    end
  end
end