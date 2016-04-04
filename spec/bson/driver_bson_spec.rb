require 'spec_helper'

describe 'Driver common bson tests' do

  specs = DRIVER_COMMON_BSON_TESTS.map { |file| BSON::CommonDriver::Spec.new(file) }

  specs.each do |spec|

    context(spec.description) do

      spec.valid_tests.each do |test|

        context(test.description << ' - ' << test.string) do

          it 'serializes to json correctly', if: test.ext_json do
            expect(test.document_as_json).to eq(test.ext_json)
          end

          it 'displays as the correct string' do
            expect(test.object.to_s).to eq(test.string)
          end

          it 'instantiates the correct object from a string', if: test.from_extjson do
            expect(test.klass.from_string(test.string)).to eq(test.object)
          end

          it 'roundtrips correctly' do
            expect(test.reencoded_hex.upcase).to eq(test.subject)
          end
        end
      end

      spec.invalid_tests.each do |test|

        context(test.description) do

          it 'raises an exception when parsing', if: test.parse_error do
            expect {
              test.parse_string
            }.to raise_error(test.parse_error)
          end
        end
      end
    end
  end
end
