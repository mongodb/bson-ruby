# Copyright (C) 2009-2014 MongoDB Inc.
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
    include JSON

    # A code with scope is type 0x0F in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 15.chr.force_encoding(BINARY).freeze

    # Key for the code when the object is converted to extended json.
    #
    # @since 5.1.0
    CODE_EXTENDED_JSON_KEY = '$code'.freeze

    # Key for the scope when the object is converted to extended json.
    #
    # @since 5.1.0
    SCOPE_EXTENDED_JSON_KEY = '$scope'.freeze

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
    # @note The extended JSON representation is the same as the
    #   normal JSON representation.
    #
    # @since 2.0.0
    def as_json(*args)
      { CODE_EXTENDED_JSON_KEY => javascript,
        SCOPE_EXTENDED_JSON_KEY => scope }
    end
    alias :as_extended_json :as_json

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
    # @return [ BSON::ByteBuffer ] The buffer with the encoded object.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
      position = buffer.length
      buffer.put_int32(0)
      buffer.put_string(javascript)
      scope.to_bson(buffer)
      buffer.replace_int32(position, buffer.length - position)
    end

    class << self

      # Deserialize a code with scope from BSON.
      #
      # @param [ ByteBuffer ] buffer The byte buffer.
      #
      # @return [ TrueClass, FalseClass ] The decoded code with scope.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def from_bson(buffer)
        buffer.get_int32 # Throw away the total length.
        new(buffer.get_string, ::Hash.from_bson(buffer))
      end

      # Create a CodeWithScope object from JSON data.
      #
      # @example Instantiate a code with scope from JSON hash data.
      #   BSON::CodeWithScope.json_create(hash)
      #
      # @param [ Hash ] json The json data.
      #
      # @return [ CodeWithScope ] The new CodeWithScope object.
      #
      # @since 5.1.0
      def json_create(json)
        new(json[CODE_EXTENDED_JSON_KEY], json[SCOPE_EXTENDED_JSON_KEY])
      end
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, self)
    BSON::ExtendedJSON.register(self, CODE_EXTENDED_JSON_KEY, SCOPE_EXTENDED_JSON_KEY)
  end
end
