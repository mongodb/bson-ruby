require 'spec_helper'

describe 'Driver common bson tests' do

  specs = DRIVER_COMMON_BSON_TESTS.map { |file| BSON::CommonDriver::Spec.new(file) }

  specs.each do |spec|

    context(spec.description) do

      spec.valid_tests.each do |test|

        context(test.description << ' - ' << test.string) do

          it 'decodes the subject and displays as the correct string' do
            expect(test.object.to_s).to eq(test.expected_to_string)
          end

          it 'encodes the decoded object correctly (roundtrips)' do
            expect(test.reencoded_hex).to eq(test.subject)
          end

          it 'creates the correct object from extended json', if: test.from_ext_json? do
            expect(test.from_json).to eq(test.object)
          end

          it 'creates the correct extended json document from the decoded object', if: test.to_ext_json? do
            expect(test.document_as_json).to eq(test.ext_json)
          end

          it 'parses the string value to the same value as the decoded document', if: test.from_ext_json? do
            expect(BSON::Decimal128.from_string(test.string)).to eq(test.object)
          end

          it 'parses the #to_s (match_string) value to the same value as the decoded document', if: test.match_string do
            expect(BSON::Decimal128.from_string(test.match_string)).to eq(test.object)
          end

          it 'can be converted to a native type' do
            expect(test.native_type_conversion).to be_a(test.native_type)
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
