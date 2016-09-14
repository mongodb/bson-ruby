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

require 'json'
require 'bigdecimal'

module BSON
  module CommonDriver

    # Represents a Common Driver specification test.
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
      # @param [ String ] file The name of the yaml file.
      #
      # @since 4.2.0
      def initialize(file)
        @spec = ::JSON.parse(File.read(file))
        @valid = @spec['valid'] || []
        @invalid = @spec['parseErrors'] || []
        @description = @spec['description']
        @test_key = @spec['test_key']
      end

      # Get a list of tests that don't raise exceptions.
      #
      # @example Get the list of valid tests.
      #   spec.valid_tests
      #
      # @return [ Array<BSON::CommonDriver::Test> ] The list of valid Tests.
      #
      # @since 4.2.0
      def valid_tests
        @valid_tests ||=
          @valid.collect do |test|
            BSON::CommonDriver::Test.new(self, test)
          end
      end

      # Get a list of tests that raise exceptions.
      #
      # @example Get the list of invalid tests.
      #   spec.invalid_tests
      #
      # @return [ Array<BSON::CommonDriver::Test> ] The list of invalid Tests.
      #
      # @since 4.2.0
      def invalid_tests
        @invalid_tests ||=
          @invalid.collect do |test|
            BSON::CommonDriver::Test.new(self, test)
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

    # Represents a single CommonDriver test.
    #
    # @since 4.2.0
    class Test

      # The test description.
      #
      # @return [ String ] The test description.
      #
      # @since 4.2.0
      attr_reader :description

      # The test subject.
      #
      # @return [ String ] The test subject.
      #
      # @since 4.2.0
      attr_reader :subject

      # The string to use to create a Decimal128.
      #
      # @return [ String ] The string to use in creating a Decimal128 object.
      #
      # @since 4.2.0
      attr_reader :string

      # The expected string representation of the Decimal128 object.
      #
      # @return [ String ] The object as a string.
      #
      # @since 4.2.0
      attr_reader :match_string

      # The json representation of the object.
      #
      # @return [ Hash ] The json representation of the object.
      #
      # @since 4.2.0
      attr_reader :ext_json

      # Instantiate the new Test.
      #
      # @example Create the test.
      #   Test.new(test)
      #
      # @param [ CommonDriver::Spec ] spec The test specification.
      # @param [ Hash ] test The test specification.
      #
      # @since 4.2.0
      def initialize(spec, test)
        @spec = spec
        @description = test['description']
        @string = test['string']
        @match_string = test['match_string']
        @ext_json = ::JSON.parse(test['extjson']) if test['extjson']
        @from_ext_json = test['from_extjson'].nil? ? true : test['from_extjson']
        @to_ext_json = test['to_extjson'].nil? ? true : test['to_extjson']
        @subject = test['subject']
        @test_key = spec.test_key
      end

      # Get the reencoded document in hex format.
      #
      # @example Get the reencoded document as hex.
      #   test.reencoded_hex
      #
      # @return [ String ] The reencoded document in hex format.
      #
      # @since 4.2.0
      def reencoded_hex
        decoded_document.to_bson.to_s.unpack("H*").first.upcase
      end

      # The object tested.
      #
      # @example Get the object for this test.
      #   test.object
      #
      # @return [ BSON::Object ] The object.
      #
      # @since 4.2.0
      def object
        @object ||= decoded_document[@test_key]
      end

      # The object as json, in a document with the test key.
      #
      # @example Get a document with the object at the test key.
      #   test.document_as_json
      #
      # @return [ BSON::Document ] The json document.
      #
      # @since 4.2.0
      def document_as_json
        { @test_key => object.as_json }
      end

      # Use the string in the extended json to instantiate the bson object.
      #
      # @example Get a bson object from the string in the extended json.
      #   test.from_json
      #
      # @return [ BSON::Object ] The BSON object.
      #
      # @since 4.2.0
      def from_json_string
        klass.from_string(@ext_json[@test_key][klass::EXTENDED_JSON_KEY])
      end

      # Create an object from the given test string.
      #
      # @example
      #   test.parse_string
      #
      # @return [ BSON::Object ] The object.
      #
      # @since 4.2.0
      def parse_string
        klass.from_string(string)
      end

      # Attempt to create an object from an invalid string.
      #
      # @example
      #   test.parse_invalid_string
      #
      # @raise [ Error ] Parsing an invalid string will raise an error.
      #
      # @since 4.2.0
      def parse_invalid_string
        klass.from_string(subject)
      end

      # The class of the object being tested.
      #
      # @example
      #   test.klass
      #
      # @return [ Class ] The object class.
      #
      # @since 4.2.0
      def klass
        @spec.klass
      end

      # The error class of a parse error.
      #
      # @example
      #   test.parse_error
      #
      # @return [ Class ] The parse error class.
      #
      # @since 4.2.0
      def parse_error
        klass::InvalidRange
      end

      # Whether the object can be instantiated from extended json.
      #
      # @example Check if an object can be instantiated from the extended json.
      #  test.from_ex_json?
      #
      # @return [ true, false ] If the object can be instantiated from
      #   the provided extended json.
      #
      # @since 4.2.0
      def from_ext_json?
        @ext_json && @from_ext_json
      end

      # Whether the object can be represented as extended json.
      #
      # @example Check if an object can be represented as extended json.
      #  test.to_ext_json?
      #
      # @return [ true, false ] If the object can be represented as
      #   extended json.
      #
      # @since 4.2.0
      def to_ext_json?
        @ext_json && @to_ext_json
      end

      # Whether the object can be instantiated from a string.
      #
      # @example Check if an object can be instantiated from a string.
      #  test.from_string?
      #
      # @return [ true, false ] If the object can be instantiated from a string.
      #
      # @since 4.2.0
      def from_string?
        @string && @from_ext_json
      end

      # The expected string representation of the test object.
      #
      # @example Get the expected String representation of the test object.
      #  test.expected_to_string
      #
      # @return [ String ] The expected string representation.
      #
      # @since 4.2.0
      def expected_to_string
        match_string || string
      end

      # The Ruby class to which this bson object can be converted via a helper.
      #
      # @example Get the native type to which this object can be converted.
      #  test.native_type
      #
      # @return [ Class ] The Ruby native type.
      #
      # @since 4.2.0
      def native_type
        klass::NATIVE_TYPE
      end

      # Get the object converted to an instance of the native Ruby type.
      #
      # @example Get a native Ruby instance.
      #  test.native_type_conversion
      #
      # @return [ Object ] An instance of the Ruby native type.
      #
      # @since 4.2.0
      def native_type_conversion
        object.send("to_#{to_snake_case(native_type)}")
      end

      private

      def to_snake_case(string)
        string.to_s.gsub(/::/, '/').
            gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
            gsub(/([a-z\d])([A-Z])/,'\1_\2').
            tr("-", "_").
            downcase
      end

      def decoded_document
        @document ||= (data = [ @subject ].pack('H*')
          buffer = BSON::ByteBuffer.new(data)
          BSON::Document.from_bson(buffer))
      end
    end
  end
end
