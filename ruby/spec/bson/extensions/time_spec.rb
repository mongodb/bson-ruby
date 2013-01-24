require 'spec_helper'

module BSON
  describe Time do
    let(:time) { Time.now }

    context 'when serialized' do
      it 'should have BSON type \x09' do
        time.bson_type.should == "\x09"
      end
    end
  end
end