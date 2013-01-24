require 'spec_helper'

module BSON
  describe Float do
    let(:float) { 3.14159 }

    context 'when serialized' do
      it 'should have BSON type \x01' do
        float.bson_type.should == "\x01"
      end

      it 'should represent the value as a 64-bit double' do
        float.bson_value.should == [float].pack(FLOAT_PACK)
      end
    end
  end
end