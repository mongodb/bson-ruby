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

  # Injects behaviour for encoding and decoding integer values to and from
  # raw bytes as specified by the BSON spec.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module Integer

    # A 32bit integer is type 0x10 in the BSON spec.
    #
    # @since 2.0.0
    INT32_TYPE = 16.chr.force_encoding(BINARY).freeze

    # A 64bit integer is type 0x12 in the BSON spec.
    #
    # @since 2.0.0
    INT64_TYPE = 18.chr.force_encoding(BINARY).freeze

    # The maximum 32 bit integer value.
    #
    # @since 2.0.0
    MAX_32BIT = (1 << 31) - 1

    # The maximum 64 bit integer value.
    #
    # @since 2.0.0
    MAX_64BIT = (1 << 63) - 1

    # The minimum 32 bit integer value.
    #
    # @since 2.0.0
    MIN_32BIT = -(1 << 31)

    # The minimum 64 bit integer value.
    #
    # @since 2.0.0
    MIN_64BIT = -(1 << 63)

    # The BSON index size.
    #
    # @since 2.0.0
    BSON_INDEX_SIZE = 1024.freeze

    # A hash of index values for array optimization.
    #
    # @since 2.0.0
    BSON_ARRAY_INDEXES = ::Array.new(BSON_INDEX_SIZE) do |i|
      (i.to_s.force_encoding(BINARY) << NULL_BYTE).freeze
    end.freeze

    # Is this integer a valid BSON 32 bit value?
    #
    # @example Is the integer a valid 32 bit value?
    #   1024.bson_int32?
    #
    # @return [ true, false ] If the integer is 32 bit.
    #
    # @since 2.0.0
    def bson_int32?
      (MIN_32BIT <= self) && (self <= MAX_32BIT)
    end

    # Is this integer a valid BSON 64 bit value?
    #
    # @example Is the integer a valid 64 bit value?
    #   1024.bson_int64?
    #
    # @return [ true, false ] If the integer is 64 bit.
    #
    # @since 2.0.0
    def bson_int64?
      (MIN_64BIT <= self) && (self <= MAX_64BIT)
    end

    # Get the BSON type for this integer. Will depend on whether the integer
    # is 32 bit or 64 bit.
    #
    # @example Get the BSON type for the integer.
    #   1024.bson_type
    #
    # @return [ String ] The single byte BSON type.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def bson_type
      bson_int32? ? INT32_TYPE : (bson_int64? ? INT64_TYPE : out_of_range!)
    end

    # Get the integer as encoded BSON.
    #
    # @example Get the integer as encoded BSON.
    #   1024.to_bson
    #
    # @return [ String ] The encoded string.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson(encoded = ''.force_encoding(BINARY))
      if bson_int32?
        to_bson_int32(encoded)
      elsif bson_int64?
        to_bson_int64(encoded)
      else
        out_of_range!
      end
    end

    # Convert the integer to a 32 bit (4 bytes) raw bytes string.
    #
    # @example Convert the integer to it's 32 bit bytes.
    #   1024.to_bson_int32
    #
    # @param [ String ] encoded The string to encode to.
    #
    # @return [ String ] The encoded string.
    #
    # @since 2.0.0
    def to_bson_int32(encoded)
      append_bson_int32(encoded)
    end

    # Convert the integer to a 64 bit (8 bytes) raw bytes string.
    #
    # @example Convert the integer to it's 64 bit bytes.
    #   1024.to_bson_int64
    #
    # @param [ String ] encoded The string to encode to.
    #
    # @return [ String ] The encoded string.
    #
    # @since 2.0.0
    def to_bson_int64(encoded)
      append_bson_int32(encoded)
      encoded << ((self >> 32) & 255)
      encoded << ((self >> 40) & 255)
      encoded << ((self >> 48) & 255)
      encoded << ((self >> 56) & 255)
    end

    def to_bson_key(encoded = ''.force_encoding(BINARY))
      if self < BSON_INDEX_SIZE
        encoded << BSON_ARRAY_INDEXES[self]
      else
        self.to_s.to_bson_cstring(encoded)
      end
    end

    private

    def append_bson_int32(encoded)
      encoded << (self & 255)
      encoded << ((self >> 8) & 255)
      encoded << ((self >> 16) & 255)
      encoded << ((self >> 24) & 255)
    end

    def out_of_range!
      raise RangeError.new("#{self} is not a valid 8 byte integer value.")
    end

  end

  # Enrich the core Integer class with this module.
  #
  # @since 2.0.0
  ::Integer.send(:include, Integer)
end
