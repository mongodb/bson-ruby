# Copyright (C) 2014-2015 MongoDB, Inc.
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
  module DriverDecimal128

    # Represents a Decimal128 specification test.
    #
    # @since 4.1.0
    class Spec

      # The spec description.
      #
      # @return [ String ] description The spec description.
      #
      # @since 4.1.0
      attr_reader :description

      # Instantiate the new spec.
      #
      # @example Create the spec.
      #   Spec.new(file)
      #
      # @param [ String ] file The name of the yaml file.
      #
      # @since 4.1.0
      def initialize(file)
        File.open(file) do |file|
          @spec = YAML.load(ERB.new(file.read).result)
        end
        @valid = @spec['valid']
        @invalid = @spec['parseErrors']
      end

      # Get a list of tests that don't raise exceptions.
      #
      # @example Get the list of valid tests.
      #   spec.valid_tests
      #
      # @return [ Array<BSON::DriverDecimal128::Test> ] The list of valid Tests.
      #
      # @since 4.1.0
      def valid_tests
        @valid_tests ||=
          @valid.collect do |test|
            BSON::DriverDecimal128::Test.new(test)
          end
      end

      # Get a list of tests that raise exceptions.
      #
      # @example Get the list of invalid tests.
      #   spec.invalid_tests
      #
      # @return [ Array<BSON::DriverDecimal128::Test> ] The list of invalid Tests.
      #
      # @since 4.1.0
      def invalid_tests
        @invalid_tests ||=
          @invalid.collect do |test|
            BSON::DriverDecimal128::Test.new(test)
          end
      end
    end

    # Represents a single Decimal128 test.
    #
    # @since 4.1.0
    class Test

      # The test description.
      #
      # @return [ String ] description The test description.
      #
      # @since 4.1.0
      attr_reader :description

      # The test subject.
      #
      # @return [ String ] subject The test subject.
      #
      # @since 4.1.0
      attr_reader :subject

      # The string representing the decimal128.
      #
      # @return [ String ] string The decimal128 as a string.
      #
      # @since 4.1.0
      attr_reader :string

      # The json representation of the decimal128.
      #
      # @return [ Hash ] ext_json The json representation of the decimal128.
      #
      # @since 4.1.0
      attr_reader :ext_json

      # Instantiate the new Test.
      #
      # @example Create the test.
      #   Test.new(test)
      #
      # @param [ Hash ] test The test specification.
      #
      # @since 4.1.0
      def initialize(test)
        @description = test['description']
        @string = test['string']
        @ext_json = test['extjson']
        @subject = test['subject']
      end

      # Get the reencoded document in hex format.
      #
      # @example Get the reencoded document as hex.
      #   test.reencoded_hex
      #
      # @return [ String ] The reencoded document in hex format.
      #
      # @since 4.1.0
      def reencoded_hex
        decoded_document.to_bson.to_s.unpack("H*").first
      end

      # The decimal128 object described by this test.
      #
      # @example Get the decimal128 object for this test.
      #   test.decimal
      #
      # @return [ BSON::Decimal128 ] The decimal128 object.
      #
      # @since 4.1.0
      def decimal
        @decimal ||= decoded_document['d']
      end

      private

      def decoded_document
        @document ||= (data = [ @subject ].pack('H*')
          buffer = BSON::ByteBuffer.new(data)
          BSON::Document.from_bson(buffer))
      end
    end
  end
end
