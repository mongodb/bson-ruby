# frozen_string_literal: true
# Copyright (C) 2009-2020 MongoDB Inc.
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
    BSON_TYPE = ::String.new(13.chr, encoding: BINARY).freeze

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
    # @since 2.0.0
    # @deprecated Use as_extended_json instead.
    def as_json(*args)
      as_extended_json
    end

    # Converts this object to a representation directly serializable to
    # Extended JSON (https://github.com/mongodb/specifications/blob/master/source/extended-json.rst).
    #
    # @option opts [ nil | :relaxed | :legacy ] :mode Serialization mode
    #   (default is canonical extended JSON)
    #
    # @return [ Hash ] The extended json representation.
    def as_extended_json(**options)
      { "$code" => javascript }
    end

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

    # Deserialize code from BSON.
    #
    # @param [ ByteBuffer ] buffer The byte buffer.
    #
    # @option options [ nil | :bson ] :mode Decoding mode to use.
    #
    # @return [ TrueClass, FalseClass ] The decoded code.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def self.from_bson(buffer, **options)
      new(buffer.get_string)
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, self)
  end
end
