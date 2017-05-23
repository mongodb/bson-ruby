# Copyright (C) 2016 MongoDB, Inc.
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

module BSON
  module Corpus

    # Represents a test from the driver BSON Corpus.
    #
    # @since 4.2.0
    class Spec

      # The spec description.
      #
      # @return [ String ] The spec description.
      #
      # @since 4.2.0
      attr_reader :description

      # The document key of the object to test.
      #
      # @return [ String ] The document key.
      #
      # @since 4.2.0
      attr_reader :test_key

      # Instantiate the new spec.
      #
      # @example Create the spec.
      #   Spec.new(file)
      #
      # @param [ String ] file The name of the json file.
      #
      # @since 4.2.0
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
      # @return [ Array<BSON::Corpus::Test> ] The list of valid Tests.
      #
      # @since 4.2.0
      def valid_tests
        @valid_tests ||=
          @valid.collect do |test|
            BSON::Corpus::Test.new(self, test)
          end
      end

      # Get a list of tests that raise exceptions.
      #
      # @example Get the list of invalid tests.
      #   spec.invalid_tests
      #
      # @return [ Array<BSON::Corpus::Test> ] The list of invalid Tests.
      #
      # @since 4.2.0
      def invalid_tests
        @invalid_tests ||=
          @invalid.collect do |test|
            BSON::Corpus::Test.new(self, test)
          end
      end

      # The class of the bson object to test.
      #
      # @example Get the class of the object to test.
      #   spec.klass
      #
      # @return [ Class ] The object class.
      #
      # @since 4.2.0
      def klass
        @klass ||= BSON.const_get(description)
      end
    end

    # Represents a single BSON Corpus test.
    #
    # @since 4.2.0
    class Test

      # The test description.
      #
      # @return [ String ] The test description.
      #
      # @since 4.2.0
      attr_reader :description

      # Name of a field in a valid test case extjson document that should be
      #   checked against the case's string field.
      #
      # @return [ String ] The json representation of the object.
      #
      # @since 4.2.0
      attr_reader :test_key

      # Instantiate the new Test.
      #
      # @example Create the test.
      #   Test.new(test)
      #
      # @param [ Corpus::Spec ] spec The test specification.
      # @param [ Hash ] test The test specification.
      #
      # @since 4.2.0
      def initialize(spec, test)
        @spec = spec
        @description = test['description']
        @canonical_bson = test['canonical_bson']
        @extjson = ::JSON.parse(test['extjson']) if test['extjson']
        @canonical_extjson = ::JSON.parse(test['canonical_extjson']) if test['canonical_extjson']
        @bson = test['bson']
        @test_key = spec.test_key
      end

      # The correct representation of the subject as bson.
      #
      # @example Get the correct representation of the subject as bson.
      #   test.correct_bson
      #
      # @return [ String ] The correct bson bytes.
      #
      # @since 4.2.0
      def correct_bson
        @correct_bson ||= decode_hex(@canonical_bson || @bson)
      end

      # Given the hex representation of bson, decode it into a Document,
      #   then reencoded it to bson.
      #
      # @example Decoded the bson hex representation, then reencode.
      #   test.reencoded_bson
      #
      # @return [ String ] The reencoded bson bytes.
      #
      # @since 4.2.0
      def reencoded_bson
        bson_bytes = decode_hex(@bson)
        buffer = BSON::ByteBuffer.new(bson_bytes)
        doc = BSON::Document.from_bson(buffer)
        force_int64_from_bytes(bson_bytes, doc)
        doc.to_bson.to_s
      end

      # Given the hex representation of the canonical bson, decode it into a Document,
      #   then reencoded it to bson.
      #
      # @example Decoded the canonical bson hex representation, then reencode.
      #   test.reencoded_canonical_bson
      #
      # @return [ String ] The reencoded canonical bson bytes.
      #
      # @since 4.2.0
      def reencoded_canonical_bson
        bson_bytes = decode_hex(@canonical_bson)
        buffer = BSON::ByteBuffer.new(bson_bytes)
        BSON::Document.from_bson(buffer).to_bson.to_s
      end

      # Whether the canonical bson should be tested.
      #
      # @example Determine if the canonical bson should be tested.
      #   test.test_canonical_bson?
      #
      # @return [ true, false ] Whether the canonical bson should be tested.
      #
      # @since 4.2.0
      def test_canonical_bson?
        @canonical_bson && (@bson != @canonical_bson)
      end

      # The correct representation of the subject as extended json.
      #
      # @example Get the correct representation of the subject as extended json.
      #   test.correct_extjson
      #
      # @return [ String ] The correct extended json representation.
      #
      # @since 4.2.0
      def correct_extjson
        @canonical_extjson || @extjson
      end

      # Whether the extended json should be tested.
      #
      # @example Determine if the extended json should be tested.
      #   test.test_extjson?
      #
      # @return [ true, false ] Whether the extended json should be tested.
      #
      # @since 4.2.0
      def test_extjson?
        !!correct_extjson
      end

      # Get the extended json representation of the decoded doc from the provided
      #   bson hex representation.
      #
      # @example Get the extended json representation of the decoded doc.
      #   test.extjson_from_encoded_bson
      #
      # @return [ Hash ] The extended json representation.
      #
      # @since 4.2.0
      def extjson_from_bson
        subject = decode_hex(@bson)
        buffer = BSON::ByteBuffer.new(subject)
        doc = BSON::Document.from_bson(buffer)
        force_int64_from_bytes(subject, doc)
        ::JSON.parse(doc.to_extended_json)
      end

      # Get the extended json representation of the decoded doc from the provided
      #   canonical bson hex representation.
      #
      # @example Get the extended json representation of the canonical decoded doc.
      #   test.extjson_from_canonical_bson
      #
      # @return [ Hash ] The extended json representation.
      #
      # @since 4.2.0
      def extjson_from_canonical_bson
        subject = decode_hex(@canonical_bson)
        buffer = BSON::ByteBuffer.new(subject)
        ::JSON.parse(BSON::Document.from_bson(buffer).to_extended_json)
      end

      # Get the extended json representation of the decoded doc from the provided
      #   extended json representation. (Verifies roundtrip)
      #
      # @example Get the extended json representation of the canonical decoded doc.
      #   test.extjson_from_encoded_extjson
      #
      # @return [ Hash ] The extended json representation.
      #
      # @since 4.2.0
      def extjson_from_encoded_extjson
        doc = BSON::Document.new(@extjson)
        ::JSON.parse(doc.to_extended_json)
      end

      private

      def decode_hex(obj)
        [ obj ].pack('H*')
      end

      # Account for the fact that integers are serialized into int64 or int32
      # depending on which range they fit into.
      def force_int64_from_bytes(bytes, doc)
        if doc[@test_key].is_a?(Integer) &&
            doc[@test_key].bson_int32? &&
            bytes[4] == BSON::Int64::BSON_TYPE
          doc[@test_key] = BSON::Int64.new(doc[@test_key])
        end
      end
    end
  end
end
