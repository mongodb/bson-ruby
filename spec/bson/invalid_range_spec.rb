require 'spec_helper'

describe BSON::Decimal128::InvalidRange do

  describe '#message' do

    let(:error) do
      described_class.new(6112, "123")
    end

    it 'includes the exponent and significand in the error message' do
      expect(error.message).to match(/6112/)
      expect(error.message).to match(/123/)
    end
  end
end
