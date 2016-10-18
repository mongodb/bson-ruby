require 'spec_helper'

describe 'Driver BSON Corpus spec tests' do

  specs = BSON_CORPUS_TESTS.map { |file| BSON::Corpus::Spec.new(file) }

  specs.each do |spec|

    context(spec.description) do

      spec.valid_tests.each do |test|

        context(test.description) do

          it 'roundtrips the bson correctly' do
            expect(test.reencoded_bson).to eq(test.correct_bson)
          end

          context 'when the bson provided results from an incorrect encoder', if: test.test_canonical_bson? do

            it 'encodes the canonical bson correctly' do
              expect(test.reencoded_canonical_bson).to eq(test.correct_bson)
            end
          end

          context 'when the document can be represented as extended json', if: test.test_extjson? do

            it 'decodes from bson, then encodes the document as extended json correctly' do
              expect(test.extjson_from_bson).to eq(test.correct_extjson)
              expect(test.extjson_from_bson[test.test_key]).to eq(test.correct_extjson[test.test_key])
            end

            it 'decodes from extended json, then encodes the document as extended json correctly' do
              expect(test.extjson_from_encoded_extjson).to eq(test.correct_extjson)
              expect(test.extjson_from_encoded_extjson[test.test_key]).to eq(test.correct_extjson[test.test_key])
            end

            context 'when the canonical bson can be represented as extended json', if: (test.test_canonical_bson? && test.test_extjson?) do

              it 'encodes the canonical bson correctly as extended json' do
                expect(test.extjson_from_canonical_bson).to eq(test.correct_extjson)
                expect(test.extjson_from_canonical_bson[test.test_key]).to eq(test.correct_extjson[test.test_key])
              end
            end
          end
        end
      end
    end
  end
end
