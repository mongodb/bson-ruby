require 'spec_helper'

module BSON
  describe Array do
    let(:array) { ['a', 'b', 'c'] }

    context 'when serialized' do
      it 'should have BSON type \x04' do
        array.bson_type.should == "\x04"
      end

      describe "bson value" do
        let (:bson) { array.bson_value }

        it 'should start with an int32 representing the bytesize' do
          bson[0..4].unpack(INT32_PACK).first == bson[4..-1].bytesize
        end

        it 'should be a hash with index values as keys' do
          bson.should == BSON::Document[
            '1' => 'a',
            '2' => 'b',
            '3' => 'c'
          ].to_bson
        end

        it 'should end with a null byte' do
          bson[-1].should == NULL_BYTE
        end
      end
    end
  end
end