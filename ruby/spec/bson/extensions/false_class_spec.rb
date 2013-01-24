require 'spec_helper'

module BSON
  describe FalseClass do
    context 'when serialized' do
      it 'should have BSON type \x08' do
        false.bson_type.should == "\x08"
      end

      it 'should have BSON value \x00' do
        false.bson_value.should == "\x00"
      end
    end
  end
end