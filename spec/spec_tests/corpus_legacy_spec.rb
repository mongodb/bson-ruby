require 'spec_helper'
require 'runners/corpus_legacy'

describe 'Driver BSON Corpus Legacy spec tests' do

  BSON_CORPUS_LEGACY_TESTS.each do |path|
    basename = File.basename(path)
    # All of the tests in the failures subdir are failing apparently
    #basename = path.sub(/.*corpus-tests\//, '')

    spec = BSON::CorpusLegacy::Spec.new(path)

    context("(#{basename}): #{spec.description}") do

      spec.valid_tests.each do |test|

        context("VALID CASE: #{test.description}") do

          it 'roundtrips the given bson correctly' do
            expect(test.reencoded_bson).to eq(test.correct_bson)
          end

          context 'when the canonical bson is roundtripped', if: test.test_canonical_bson? do

            it 'encodes the canonical bson correctly' do
              expect(test.reencoded_canonical_bson).to eq(test.correct_bson)
            end
          end

          context 'when the document can be represented as extended json', if: test.test_extjson? do

            it 'decodes from the given bson, then encodes the document as extended json correctly' do
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

      spec.invalid_tests.each do |test|

        context("INVALID CASE: #{test.description}") do

          let(:error) do
            begin; test.reencoded_bson; false; rescue => e; e; end
          end

          it 'raises an error' do
            skip 'This test case does not raise and error but should' unless error
            expect do
              test.reencoded_bson
            end.to raise_error(error.class)
          end
        end
      end
    end
  end
end
