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

  # Represents a $maxKey type, which compares less than any other value in the
  # specification.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  class Int64

    # A boolean is type 0x08 in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 18.chr.force_encoding(BINARY).freeze

    # Constant for the int 64 pack directive.
    #
    # @since 2.0.0
    PACK = "q<".freeze

    # Deserialize an Integer from BSON.
    #
    # @param [ ByteBuffer ] buffer The byte buffer.
    #
    # @return [ Integer ] The decoded Integer.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def self.from_bson(buffer)
      buffer.get_int64
    end

    # Instantiate a BSON Int64.
    #
    # @param [ Integer ] integer The 64-bit integer.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 4.2.0
    def initialize(integer)
      out_of_range! unless integer.bson_int64?
      @integer = integer.freeze
    end

    # Append the integer as encoded BSON to a ByteBuffer.
    #
    # @example Encoded the integer and append to a ByteBuffer.
    #   int64.to_bson
    #
    # @return [ BSON::ByteBuffer ] The buffer with the encoded integer.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 4.2.0
    def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
      buffer.put_int64(@integer)
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
      @integer.to_bson_key(validating_keys)
    end

    private

    def out_of_range!
      raise RangeError.new("#{self} is not a valid 8 byte integer value.")
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, self)
  end
end
