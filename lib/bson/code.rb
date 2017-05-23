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

  # Represents a code type, which is a wrapper around javascript code.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  class Code
    include JSON

    # A code is type 0x0D in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 13.chr.force_encoding(BINARY).freeze

    # Key for the code object when converted to extended json.
    #
    # @since 5.1.0
    EXTENDED_JSON_KEY = '$code'.freeze

    # @!attribute javascript
    #   @return [ String ] The javascript code.
    #   @since 2.0.0
    attr_reader :javascript

    # Determine if this code object is equal to another object.
    #
    # @example Check the code equality.
    #   code == other
    #
    # @param [ Object ] other The object to compare against.
    #
    # @return [ true, false ] If the objects are equal.
    #
    # @since 2.0.0
    def ==(other)
      return false unless other.is_a?(Code)
      javascript == other.javascript
    end

    # Get the code as JSON hash data.
    #
    # @example Get the code as a JSON hash.
    #   code.as_json
    #
    # @return [ Hash ] The code as a JSON hash.
    #
    # @note The extended JSON representation is the same as the
    #   normal JSON representation.
    #
    # @since 2.0.0
    def as_json(*args)
      { EXTENDED_JSON_KEY => javascript }
    end
    alias :as_extended_json :as_json

    # Instantiate the new code.
    #
    # @example Instantiate the new code.
    #   BSON::Code.new("this.value = 5")
    #
    # @param [ String ] javascript The javascript code.
    #
    # @since 2.0.0
    def initialize(javascript = "")
      @javascript = javascript
    end

    # Encode the javascript code.
    #
    # @example Encode the code.
    #   code.to_bson
    #
    # @return [ BSON::ByteBuffer ] The buffer with the encoded object.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
      buffer.put_string(javascript) # @todo: was formerly to_bson_string
    end

    class << self

      # Deserialize code from BSON.
      #
      # @param [ ByteBuffer ] buffer The byte buffer.
      #
      # @return [ TrueClass, FalseClass ] The decoded code.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def from_bson(buffer)
        new(buffer.get_string)
      end

      # Create a Code object from JSON data.
      #
      # @example Instantiate a code from JSON hash data.
      #   BSON::Code.json_create(hash)
      #
      # @param [ Hash ] json The json data.
      #
      # @return [ Code ] The new Code object.
      #
      # @since 5.1.0
      def json_create(json)
        new(json[EXTENDED_JSON_KEY])
      end
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, self)
    ExtendedJSON.register(self, EXTENDED_JSON_KEY)
  end
end
