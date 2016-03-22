require 'spec_helper'

describe 'Decimal128' do

  spec = BSON::DriverDecimal128::Spec.new(DRIVER_DECIMAL128_TEST)

  context(spec.description) do

    spec.valid_tests.each do |test|

      context(test.description << ' - ' << test.string) do

        it 'serializes to json correctly', if: test.ext_json do
          #expect(test.decimal.as_json).to eq(test.ext_json)
        end

        it 'displays as the correct string' do
          expect(test.decimal.to_s).to eq(test.string)
        end

        it 'instantiates the correct Decaiml128 object from a string', if: test.ext_json do
          expect(BSON::Decimal128.from_string(test.string)).to eq(test.decimal)
        end

        it 'roundtrips correctly' do
          expect(test.reencoded_hex.upcase).to eq(test.subject)
        end
      end
    end

    spec.invalid_tests.each do |test|

      context(test.description) do

        it 'raises an exception when parsing' do
          expect {
            test.parse_string
          }.to raise_error(Exception)
        end
      end
    end
  end
end
