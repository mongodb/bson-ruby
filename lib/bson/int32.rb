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

  # Represents int32 type.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  class Int32

    # A boolean is type 0x08 in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = ::String.new(16.chr, encoding: BINARY).freeze

    # The number of bytes constant.
    #
    # @since 4.0.0
    BYTES_LENGTH = 4

    # Constant for the int 32 pack directive.
    #
    # @since 2.0.0
    PACK = "l<"

    # Deserialize an Integer from BSON.
    #
    # @param [ ByteBuffer ] buffer The byte buffer.
    #
    # @option options [ nil | :bson ] :mode Decoding mode to use.
    #
    # @return [ Integer ] The decoded Integer.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def self.from_bson(buffer, **options)
      buffer.get_int32
    end

    # Instantiate a BSON Int32.
    #
    # @param [ Integer ] value The 32-bit integer.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 4.2.0
    def initialize(value)
      if value.is_a?(self.class)
        @value = value.value
        return
      end

      unless value.bson_int32?
        raise RangeError.new("#{value} cannot be stored in 32 bits")
      end
      @value = value.freeze
    end

    # Returns the value of this Int32.
    #
    # @return [ Integer ] The integer value.
    attr_reader :value

    # Append the integer as encoded BSON to a ByteBuffer.
    #
    # @example Encoded the integer and append to a ByteBuffer.
    #   int32.to_bson
    #
    # @return [ BSON::ByteBuffer ] The buffer with the encoded integer.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 4.2.0
    def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
      buffer.put_int32(value)
    end

    # Convert the integer to a BSON string key.
    #
    # @example Convert the integer to a BSON key string.
    #   int.to_bson_key
    #
    # @param [ true, false ] validating_keys If BSON should validate the key.
    #
    # @return [ String ] The string key.
    #
    # @since 4.2.0
    def to_bson_key(validating_keys = Config.validating_keys?)
      value
    end

    # Check equality of the int32 with another object.
    #
    # @param [ Object ] other The object to check against.
    #
    # @return [ true, false ] If the objects are equal.
    #
    # @since 4.4.0
    def ==(other)
      return false unless other.is_a?(Int32)
      value == other.value
    end
    alias :eql? :==
    alias :=== :==

    # Converts this object to a representation directly serializable to
    # Extended JSON (https://github.com/mongodb/specifications/blob/master/source/extended-json.rst).
    #
    # This method returns the integer value if relaxed representation is
    # requested, otherwise a $numberInt hash.
    #
    # @option opts [ nil | :relaxed | :legacy ] :mode Serialization mode
    #   (default is canonical extended JSON)
    #
    # @return [ Hash | Integer ] The extended json representation.
    def as_extended_json(**options)
      if options[:mode] == :relaxed || options[:mode] == :legacy
        value
      else
        {'$numberInt' => value.to_s}
      end
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, self)
  end
end
