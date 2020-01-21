require 'spec_helper'
require 'runners/corpus_legacy'
require 'byebug'

describe 'BSON corpus legacy spec tests' do
  # BSON_CORPUS_LEGACY_TESTS.each do |path|
    path = "#{CURRENT_PATH}/spec_tests/data/corpus_legacy/array.json"
    basename = File.basename(path)

    spec = BSON::CorpusLegacy::Spec.new(path)

    context("(#{basename}): #{spec.description}") do

      spec.valid_tests&.each do |test|

        context("valid: #{test.description}") do

          if test.canonical_bson
            let(:decoded_canonical_bson) do
              BSON::Document.from_bson(BSON::ByteBuffer.new(test.canonical_bson), mode: :legacy)
            end

            it 'round-trips canonical bson' do
              decoded_canonical_bson.to_bson.to_s.should == test.canonical_bson
            end

            it 'converts canonical bson to legacy extended json' do
              decoded_canonical_bson.as_extended_json(mode: :legacy).should == test.extjson
            end
          end

          let(:decoded_bson) do
            BSON::Document.from_bson(BSON::ByteBuffer.new(test.bson), mode: :legacy)
          end

          it 'round-trips bson' do
            decoded_bson.to_bson.to_s.should == test.bson
          end

          it 'converts canonical bson to legacy extended json' do
            decoded_bson.as_extended_json(mode: :legacy).should == test.extjson
          end
        # end
      end
    end
  end
end
