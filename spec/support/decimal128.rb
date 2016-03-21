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

# Matcher for determining if the results of the opeartion match the
# test's expected results.
#
# @since 2.0.0

# Matcher for determining if the collection's data matches the
# test's expected collection data.
#
# @since 2.0.0
RSpec::Matchers.define :match_string do |test|

  match do |actual|
    test.compare_string
  end
end

RSpec::Matchers.define :match_ext_json do |test|

  match do |actual|
    test.compare_ext_json
  end
end

RSpec::Matchers.define :round_trip do |test|

  match do |actual|
    test.reencoded == test.subject
  end
end

module BSON
  module DriverDecimal128

    # Represents a Decimal128 specification test.
    #
    # @since
    class Spec

      # @return [ String ] description The spec description.
      #
      # @since
      attr_reader :description

      # Instantiate the new spec.
      #
      # @example Create the spec.
      #   Spec.new(file)
      #
      # @param [ String ] file The name of the file.
      #
      # @since 2.0.0
      def initialize(file)
        file = File.new(file)
        @spec = YAML.load(ERB.new(file.read).result)
        file.close
        @valid = @spec['valid']
      end

      # Get a list of CRUDTests for each test definition.
      #
      # @example Get the list of CRUDTests.
      #   spec.tests
      #
      # @return [ Array<CRUDTest> ] The list of CRUDTests.
      #
      # @since 2.0.0
      def tests
        @tests ||=
          @valid.collect do |test|
            BSON::DriverDecimal128::Test.new(test, true)
          end
      end
    end

    # Represents a single CRUD test.
    #
    # @since 2.0.0
    class Test

      # The test description.
      #
      # @return [ String ] description The test description.
      #
      # @since 2.0.0
      attr_reader :description
      attr_reader :subject
      attr_reader :string
      attr_reader :ext_json

      # Instantiate the new CRUDTest.
      #
      # @example Create the test.
      #   CRUDTest.new(data, test)
      #
      # @param [ Array<Hash> ] data The documents the collection
      # must have before the test runs.
      # @param [ Hash ] test The test specification.
      #
      # @since 2.0.0
      def initialize(test, valid)
        @valid = !!valid
        @description = test['description']
        @string = test['string']
        @ext_json = test['extjson']
        @subject = test['subject']
      end

      # Run the test.
      #
      # @example Run the test.
      #   test.run(collection)
      #
      # @param [ Collection ] collection The collection the test
      #   should be run on.
      #
      # @return [ Result, Array<Hash> ] The result(s) of running the test.
      #
      # @since 2.0.0
      def high_order
        @decimal.instance_variable_get(:@high)
      end

      def low_order
        @decimal.instance_variable_get(:@low)
      end

      def compare_string
        @decimal.to_s == @string
      end

      def compare_ext_json
        @decimal.to_json == @extjson
      end

      def reencoded_hex
        decoded_document.to_bson.to_s.unpack("H*").first.upcase
      end

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
