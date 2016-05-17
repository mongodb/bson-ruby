require 'spec_helper'

describe 'Driver common bson tests' do

  specs = DRIVER_COMMON_BSON_TESTS.map { |file| BSON::CommonDriver::Spec.new(file) }

  specs.each do |spec|

    context(spec.description) do

      spec.valid_tests.each do |test|

        context(test.description << ' - ' << test.string) do

          it 'displays as the correct string' do
            expect(test.object.to_s).to eq(test.expected_to_string)
          end

          it 'encodeds the decoded object correctly (roundtrips)' do
            expect(test.reencoded_hex).to eq(test.subject)
          end

          it 'instantiates the correct object from extended json', if: test.from_ext_json? do
            expect(test.from_json).to eq(test.object)
          end

          it 'creates the correct extended json document', if: test.to_ext_json? do
            expect(test.document_as_json).to eq(test.ext_json)
          end

          it 'instantiates the correct object from a string', if: test.from_ext_json? do
            expect(BSON::Decimal128.from_string(test.string)).to eq(test.object)
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
