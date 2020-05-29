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
require 'forwardable'

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
        @spec = ::JSON.parse(File.read(file).force_encoding('utf-8'))
      end

      def description
        @spec['description']
      end

      def test_key
        @spec['test_key']
      end

      def valid_tests
        @valid_tests ||=
          @spec['valid']&.map do |test_spec|
            ValidTest.new(self, test_spec)
          end
      end

      def decode_error_tests
        @decode_error_tests ||=
          @spec['decodeErrors']&.map do |test_spec|
            DecodeErrorTest.new(self, test_spec)
          end
      end

      def parse_error_tests
        @parse_error_tests ||=
          @spec['parseErrors']&.map do |test_spec|
            ParseErrorTest.new(self, test_spec)
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

    class TestBase

      private

      def decode_hex(obj)
        [ obj ].pack('H*')
      end
    end

    # Represents a single BSON Corpus test.
    #
    # @since 4.2.0
    class ValidTest < TestBase
      extend Forwardable

      # Instantiate the new Test.
      #
      # @example Create the test.
      #   Test.new(test)
      #
      # @param [ Corpus::Spec ] spec The test specification.
      # @param [ Hash ] test The test specification.
      #
      # @since 4.2.0
      def initialize(spec, test_params)
        @spec = spec
        test_params = test_params.dup
        %w(
          description canonical_extjson relaxed_extjson
          degenerate_extjson converted_extjson
          lossy
        ).each do |key|
          instance_variable_set("@#{key}", test_params.delete(key))
        end
        %w(
          canonical_bson degenerate_bson converted_bson
          lossy
        ).each do |key|
          if test_params.key?(key)
            instance_variable_set("@#{key}", decode_hex(test_params.delete(key)))
          end
        end
        unless test_params.empty?
          raise "Test params has unprocessed keys: #{test_params}"
        end
      end

      def_delegators :@spec, :test_key

      attr_reader :description,
        :canonical_bson,
        :degenerate_bson,
        :converted_bson,
        :canonical_extjson,
        :relaxed_extjson,
        :degenerate_extjson,
        :converted_extjson

      def lossy?
        !!@lossy
      end

      def canonical_extjson_doc
        ::JSON.parse(canonical_extjson)
      end

      def relaxed_extjson_doc
        relaxed_extjson && ::JSON.parse(relaxed_extjson)
      end
    end

    class DecodeErrorTest < TestBase
      def initialize(spec, test_params)
        @spec = spec
        @description = test_params['description']
        @bson = decode_hex(test_params['bson'])
      end

      attr_reader :description, :bson
    end

    class ParseErrorTest
      def initialize(spec, test_params)
        @spec = spec
        @description = test_params['description']
        @string = test_params['string']
      end

      attr_reader :description, :string
    end
  end
end
