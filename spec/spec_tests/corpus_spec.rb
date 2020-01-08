require 'spec_helper'
require 'runners/corpus'

describe 'BSON Corpus spec tests' do

  BSON_CORPUS_TESTS.each do |path|
    basename = File.basename(path)
    # All of the tests in the failures subdir are failing apparently
    #basename = path.sub(/.*corpus-tests\//, '')

    spec = BSON::Corpus::Spec.new(path)

    context("(#{basename}): #{spec.description}") do

      spec.valid_tests&.each do |test|

        context("valid: #{test.description}") do

          let(:decoded_canonical_bson) do
            BSON::Document.from_bson(BSON::ByteBuffer.new(test.canonical_bson))
          end

          it 'round-trips canonical bson' do
            decoded_canonical_bson.to_bson.to_s.should == test.canonical_bson
          end

=begin
          it 'converts bson to canonical extended json' do
            pending
            raise NotImplementedError
          end
=end

          it 'converts bson to relaxed extended json' do
            # TODO when canonical extjson serialization is implemented,
            # this test should only be run if relaxed extjson serialization
            # is present in the spec test file
            JSON.parse(decoded_canonical_bson.to_json).should == (test.relaxed_extjson_doc || test.canonical_extjson_doc)
          end

          if test.degenerate_bson

            let(:decoded_degenerate_bson) do
              BSON::Document.from_bson(BSON::ByteBuffer.new(test.degenerate_bson))
            end

            it 'round-trips degenerate bson' do
              decoded_degenerate_bson.to_bson.to_s.should == test.degenerate_bson
            end
          end

=begin bson-ruby does not have extended json parser yet
          it 'round-trips relaxed json' do
            # TODO when canonical extjson serialization is implemented,
            # this test should only be run if relaxed extjson serialization
            # is present in the spec test file
          end
=end

=begin
          context 'when the canonical bson is roundtripped', if: test.test_canonical_bson? do

            it 'encodes the canonical bson correctly' do
              expect(test.reencoded_canonical_bson).to eq(test.correct_bson)
            end
          end

          if test.correct_relaxed_extjson
            context 'when the document can be represented as extended json' do

              it 'decodes from the given bson, then encodes the document as extended json correctly' do
                skip 'The extended json in this test case does not match' unless (test.extjson_from_bson == test.correct_relaxed_extjson)
                expect(test.extjson_from_bson).to eq(test.correct_relaxed_extjson)
                expect(test.extjson_from_bson[test.test_key]).to eq(test.correct_relaxed_extjson[test.test_key])
              end

              it 'decodes from extended json, then encodes the document as extended json correctly' do
                expect(test.extjson_from_encoded_extjson).to eq(test.correct_relaxed_extjson)
                expect(test.extjson_from_encoded_extjson[test.test_key]).to eq(test.correct_relaxed_extjson[test.test_key])
              end

              if test.test_canonical_bson?
                context 'when the canonical bson can be represented as extended json' do

                  it 'encodes the canonical bson correctly as extended json' do
                    expect(test.extjson_from_canonical_bson).to eq(test.correct_relaxed_extjson)
                    expect(test.extjson_from_canonical_bson[test.test_key]).to eq(test.correct_relaxed_extjson[test.test_key])
                  end
                end
              end
            end
          end
=end
        end
      end

      spec.decode_error_tests&.each do |test|

        context("decode error: #{test.description}") do

          let(:decoded_bson) do
            BSON::Document.from_bson(BSON::ByteBuffer.new(test.bson))
          end

          # Until bson-ruby gets an exception hierarchy, we can only rescue
          # the basic Exception here.
          # https://jira.mongodb.org/browse/RUBY-1806
          it 'raises an exception' do
            expect do
              decoded_bson
            end.to raise_error(Exception)
          end
        end
      end
    end
  end
end
