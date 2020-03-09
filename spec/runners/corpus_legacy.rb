# Copyright (C) 2016-2020 MongoDB Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'json'

module BSON
  module CorpusLegacy

    # Represents a test from the driver BSON Corpus.
    class Spec

      # The spec description.
      #
      # @return [ String ] The spec description.
      attr_reader :description

      # The document key of the object to test.
      #
      # @return [ String ] The document key.
      attr_reader :test_key

      # Instantiate the new spec.
      #
      # @example Create the spec.
      #   Spec.new(file)
      #
      # @param [ String ] file The name of the json file.
      def initialize(file)
        @spec = ::JSON.parse(File.read(file))
        @valid = @spec['valid'] || []
        @invalid = @spec['decodeErrors'] || []
        @description = @spec['description']
        @test_key = @spec['test_key']
      end

      # Get a list of tests that are expected to pass.
      #
      # @example Get the list of valid tests.
      #   spec.valid_tests
      #
      # @return [ Array<BSON::CorpusLegacy::Test> ] The list of valid Tests.
      def valid_tests
        @valid_tests ||=
          @valid.collect do |test|
            BSON::CorpusLegacy::Test.new(self, test)
          end
      end

      # Get a list of tests that raise exceptions.
      #
      # @example Get the list of invalid tests.
      #   spec.invalid_tests
      #
      # @return [ Array<BSON::CorpusLegacy::Test> ] The list of invalid Tests.
      def invalid_tests
        @invalid_tests ||=
          @invalid.collect do |test|
            BSON::CorpusLegacy::Test.new(self, test)
          end
      end

      # The class of the bson object to test.
      #
      # @example Get the class of the object to test.
      #   spec.klass
      #
      # @return [ Class ] The object class.
      def klass
        @klass ||= BSON.const_get(description)
      end
    end

    # Represents a single BSON Corpus test.
    class Test

      # The test description.
      #
      # @return [ String ] The test description.
      attr_reader :description

      # Name of a field in a valid test case extjson document that should be
      #   checked against the case's string field.
      #
      # @return [ String ] The json representation of the object.
      attr_reader :test_key

      # Instantiate the new Test.
      #
      # @example Create the test.
      #   Test.new(test)
      #
      # @param [ Corpus::Spec ] spec The test specification.
      # @param [ Hash ] test The test specification.
      def initialize(spec, test)
        @spec = spec
        @description = test['description']
        @canonical_bson = test['canonical_bson']
        @extjson = ::JSON.parse(test['extjson']) if test['extjson']
        @bson = test['bson']
        @test_key = spec.test_key
      end

      # The correct representation of the subject as bson.
      #
      # @example Get the correct representation of the subject as bson.
      #   test.correct_bson
      #
      # @return [ String ] The correct bson bytes.
      def correct_bson
        @correct_bson ||= decode_hex(@canonical_bson || @bson)
      end

      # Create a BSON::Document object from the test's bson representation
      #
      # @return [ BSON::Document ] The BSON::Document object
      def document_from_bson
        bson_bytes = decode_hex(@bson)
        buffer = BSON::ByteBuffer.new(bson_bytes)
        BSON::Document.from_bson(buffer)
      end

      # Create a BSON::Document object from the test's canonical bson
      # representation
      #
      # @return [ BSON::Document ] The BSON::Document object
      def document_from_canonical_bson
        bson_bytes = decode_hex(@canonical_bson)
        buffer = BSON::ByteBuffer.new(bson_bytes)
        BSON::Document.from_bson(buffer)
      end

      # Given the hex representation of bson, decode it into a Document,
      #   then reencoded it to bson.
      #
      # @example Decoded the bson hex representation, then reencode.
      #   test.reencoded_bson
      #
      # @return [ String ] The reencoded bson bytes.
      def reencoded_bson
        document_from_bson.to_bson.to_s
      end

      # Given the hex representation of the canonical bson, decode it into a Document,
      #   then reencoded it to bson.
      #
      # @example Decoded the canonical bson hex representation, then reencode.
      #   test.reencoded_canonical_bson
      #
      # @return [ String ] The reencoded canonical bson bytes.
      def reencoded_canonical_bson
        document_from_canonical_bson.to_bson.to_s
      end

      # Whether the canonical bson should be tested.
      #
      # @example Determine if the canonical bson should be tested.
      #   test.test_canonical_bson?
      #
      # @return [ true, false ] Whether the canonical bson should be tested.
      def test_canonical_bson?
        @canonical_bson && (@bson != @canonical_bson)
      end

      # The correct representation of the subject as extended json.
      #
      # @example Get the correct representation of the subject as extended json.
      #   test.correct_extjson
      #
      # @return [ String ] The correct extended json representation.
      def correct_extjson
        @canonical_extjson || @extjson
      end

      # Whether the extended json should be tested.
      #
      # @example Determine if the extended json should be tested.
      #   test.test_extjson?
      #
      # @return [ true, false ] Whether the extended json should be tested.
      def test_extjson?
        !!@extjson
      end

      # Get the extended json representation of the decoded doc from the provided
      #   bson hex representation.
      #
      # @example Get the extended json representation of the decoded doc.
      #   test.extjson_from_encoded_bson
      #
      # @return [ Hash ] The extended json representation.
      def extjson_from_bson
        as_legacy_extended_json(document_from_bson)
      end

      # Get the extended json representation of the decoded doc from the provided
      #   canonical bson hex representation.
      #
      # @example Get the extended json representation of the canonical decoded doc.
      #   test.extjson_from_canonical_bson
      #
      # @return [ Hash ] The extended json representation.
      def extjson_from_canonical_bson
        as_legacy_extended_json(document_from_canonical_bson)
      end

      # Get the extended json representation of the decoded doc from the provided
      #   extended json representation. (Verifies roundtrip)
      #
      # @example Get the extended json representation of the canonical decoded doc.
      #   test.extjson_from_encoded_extjson
      #
      # @return [ Hash ] The extended json representation.
      def extjson_from_encoded_extjson
        doc = BSON::Document.new(@extjson)
        as_legacy_extended_json(doc)
      end

      private

      def as_legacy_extended_json(object)
        result = object.as_extended_json(mode: :legacy)
        if object.respond_to?(:as_json)
          old_result = object.as_json
          unless result == old_result
            raise "Serializing #{object} to legacy extended json did not match between new and old APIs"
          end
        end
        result
      end

      def decode_hex(obj)
        [ obj ].pack('H*')
      end
    end
  end
end
