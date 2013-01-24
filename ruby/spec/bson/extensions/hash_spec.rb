require 'spec_helper'

module BSON
  describe Hash do
    let(:hash) { {:a => 1, :b => 2} }

    context 'when serialized' do
      it 'should have BSON type \x03' do
        hash.bson_type.should == "\x03"
      end

      describe "bson value" do
        let(:bson) { hash.bson_value }

        it 'should start with an int32 representing the bytesize' do
          bson[0..4].unpack(INT32_PACK).first == bson[4..-1].bytesize
        end

        it 'should end with a null byte' do
          bson[-1].should == NULL_BYTE
        end
      end
    end
  end
end