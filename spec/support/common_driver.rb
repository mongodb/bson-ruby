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

require 'json'

module BSON
  module CommonDriver

    # Represents a Common Driver specification test.
    #
    # @since 4.1.0
    class Spec

      # The spec description.
      #
      # @return [ String ] The spec description.
      #
      # @since 4.1.0
      attr_reader :description

      # The document key of the object to test.
      #
      # @return [ String ] The document key.
      #
      # @since 4.1.0
      attr_reader :test_key

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
      # @since 4.1.0
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
      # @since 4.1.0
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
      # @since 4.1.0
      def klass
        @klass ||= BSON.const_get(description)
      end
    end

    # Represents a single CommonDriver test.
    #
    # @since 4.1.0
    class Test

      # The test description.
      #
      # @return [ String ] The test description.
      #
      # @since 4.1.0
      attr_reader :description

      # The test subject.
      #
      # @return [ String ] The test subject.
      #
      # @since 4.1.0
      attr_reader :subject

      # The string representing the object.
      #
      # @return [ String ] The object as a string.
      #
      # @since 4.1.0
      attr_reader :string

      # The json representation of the object.
      #
      # @return [ Hash ] The json representation of the object.
      #
      # @since 4.1.0
      attr_reader :ext_json

      # Instantiate the new Test.
      #
      # @example Create the test.
      #   Test.new(test)
      #
      # @param [ CommonDriver::Spec ] spec The test specification.
      # @param [ Hash ] test The test specification.
      #
      # @since 4.1.0
      def initialize(spec, test)
        @spec = spec
        @description = test['description']
        @string = test['string']
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
      # @since 4.1.0
      def reencoded_hex
        decoded_document.to_bson.to_s.unpack("H*").first
      end

      # The object tested.
      #
      # @example Get the object for this test.
      #   test.object
      #
      # @return [ BSON::Object ] The object.
      #
      # @since 4.1.0
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
      # @since 4.1.0
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
      # @since 4.1.0
      def from_json
        klass.from_string(@ext_json[@test_key].values.first)
      end

      # Create an object from the given test string.
      #
      # @example
      #   test.parse_string
      #
      # @return [ BSON::Object ] The object.
      #
      # @since 4.1.0
      def parse_string
        klass.from_string(string)
      end

      # The class of the object being tested.
      #
      # @example
      #   test.klass
      #
      # @return [ Class ] The object class.
      #
      # @since 4.1.0
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
      # @since 4.1.0
      def parse_error
        klass::InvalidString
      end

      # Whether the object can be instantiated from extended json.
      #
      # @example Check if an object can be instantiated from the extended json.
      #  test.from_ex_json?
      #
      # @return [ true, false ] If the object can be instantiated from
      #   the provided extended json.
      #
      # @since 4.1.0
      def from_ext_json?
        @from_ext_json
      end

      # Whether the object can be represented as extended json.
      #
      # @example Check if an object can be represented as extended json.
      #  test.to_ext_json?
      #
      # @return [ true, false ] If the object can be represented as
      #   extended json.
      #
      # @since 4.1.0
      def to_ext_json?
        @to_ext_json
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
