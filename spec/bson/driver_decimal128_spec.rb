require 'spec_helper'

describe 'Decimal128' do

  spec = BSON::DriverDecimal128::Spec.new(DRIVER_DECIMAL128_TEST)

  context(spec.description) do

    spec.tests.each do |test|

      context(test.description) do

        it 'creates the correct Decimal128 object' do
          #expect(test.decimal.to_s).to eq(test.string)
        end

        it 'matches the extended json' do

        end

        it 'matches the string' do

        end

        it 'instantiates the correct object from a string' do
          expect(BSON::Decimal128.from_string(test.string)).to eq(test.decimal)
        end

        it 'serializes correctly' do
          expect(test.reencoded_hex.upcase).to eq(test.subject)
        end
      end
    end
  end
end
