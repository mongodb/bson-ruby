require 'spec_helper'

module BSON
  describe String do
    let(:string) { "test" }

    context 'when serialized' do
      it 'should have BSON type \x02' do
        string.bson_type.should == "\x02"
      end

      it 'should start with an int32 representing bytesize' do
        string.bson_value[0..4].unpack(INT32_PACK).first.should == string.length + 1
      end

      it 'should serialize the value as UTF-8' do
        string.bson_value[4..-2].should == string.encode(UTF8_ENCODING)
      end

      it 'should end with a null byte' do
        string.bson_value[-1].should == NULL_BYTE
      end
    end
  end
end