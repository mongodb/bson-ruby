# Copyright (C) 2009-2013 MongoDB Inc.
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

  # Represents a code with scope, which is a wrapper around javascript code
  # with variable scope provided.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  class CodeWithScope
    include Encodable
    include JSON

    # A code with scope is type 0x0F in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 15.chr.force_encoding(BINARY).freeze

    # @!attribute javascript
    #   @return [ String ] The javascript code.
    #   @since 2.0.0
    # @!attribute scope
    #   @return [ Hash ] The variable scope.
    #   @since 2.0.0
    attr_reader :javascript, :scope

    # Determine if this code with scope object is equal to another object.
    #
    # @example Check the code with scope equality.
    #   code_with_scope == other
    #
    # @param [ Object ] other The object to compare against.
    #
    # @return [ true, false ] If the objects are equal.
    #
    # @since 2.0.0
    def ==(other)
      return false unless other.is_a?(CodeWithScope)
      javascript == other.javascript && scope == other.scope
    end

    # Get the code with scope as JSON hash data.
    #
    # @example Get the code with scope as a JSON hash.
    #   code_with_scope.as_json
    #
    # @return [ Hash ] The code with scope as a JSON hash.
    #
    # @since 2.0.0
    def as_json(*args)
      { "$code" => javascript, "$scope" => scope }
    end

    # Instantiate the new code with scope.
    #
    # @example Instantiate the code with scope.
    #   BSON::CodeWithScope.new("this.value = name", name: "sid")
    #
    # @param [ String ] javascript The javascript code.
    # @param [ Hash ] scope The variable scope.
    #
    # @since 2.0.0
    def initialize(javascript = "", scope = {})
      @javascript = javascript
      @scope = scope
    end

    # Encode the javascript code with scope.
    #
    # @example Encode the code with scope.
    #   code_with_scope.to_bson
    #
    # @return [ String ] The encoded string.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson(encoded = ''.force_encoding(BINARY))
      # -1 because we are removing an extra byte
      out = encode_with_placeholder_and_null(BSON_ADJUST - 1, encoded) do |encoded|
        javascript.to_bson(encoded)
        scope.to_bson(encoded)
      end
      # an extra null byte has been added; we must remove it
      out.chop!
    end

    # Deserialize a code with scope from BSON.
    #
    # @param [ BSON ] bson The encoded code with scope.
    #
    # @return [ TrueClass, FalseClass ] The decoded code with scope.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def self.from_bson(bson)
      bson.read(4) # Throw away the total length.
      new(bson.read(Int32.from_bson(bson)).from_bson_string.chop!, ::Hash.from_bson(bson))
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, self)
  end
end
