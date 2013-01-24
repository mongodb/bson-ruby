require 'spec_helper'

module BSON
  describe NilClass do
    context 'when serialized' do
      it 'should have BSON type \x0A' do
        nil.bson_type.should == "\x0A"
      end

      it 'should not have a value' do
        nil.bson_value.should == nil
      end
    end
  end
end