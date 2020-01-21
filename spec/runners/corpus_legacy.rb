# Copyright (C) 2016-2019 MongoDB, Inc.
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

require 'runners/corpus'
require 'json'

module BSON
  module CorpusLegacy

    # Represents a test from the legacy BSON corpus
    class Spec < Corpus::Spec
      def valid_tests
        @valid_tests ||=
          @spec['valid']&.map do |test_spec|
            ValidTest.new(self, test_spec)
          end
      end
    end

    class ValidTest < Corpus::ValidTest
      # TODO: documentation
      def initialize(spec, test_params)
        @spec = spec
        test_params = test_params.dup

        instance_variable_set("@extjson", ::JSON.parse(test_params.delete('extjson')))
        instance_variable_set("@description", test_params.delete('description'))

        %w(
          bson canonical_bson
        ).each do |key|
          instance_variable_set("@#{key}", decode_hex(test_params.delete(key)))
        end
      end

      attr_reader :bson, :extjson
    end

    class DecodeErrorTest < Corpus::DecodeErrorTest; end
  end
end
