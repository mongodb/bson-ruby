require 'spec_helper'

module BSON
  describe Hash do
    let(:hash) { {:a => 1, :b => 2} }

    context 'when serialized' do
      it 'should have BSON type \x03' do
        hash.bson_type.should == "\x03"
      end

      it 'should be a hash with index values as keys' do
        hash.bson_value == BSON::serialize([
          '1' => 'a',
          '2' => 'b',
          '3' => 'c'
        ])
      end
    end
  end
end