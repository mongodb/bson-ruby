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

  # Injects behaviour for encoding and decoding integer values to and from
  # raw bytes as specified by the BSON spec.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module Integer

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
    BSON_INDEX_SIZE = 1024

    # A hash of index values for array optimization.
    #
    # @since 2.0.0
    BSON_ARRAY_INDEXES = ::Array.new(BSON_INDEX_SIZE) do |i|
      (i.to_s.b << NULL_BYTE).freeze
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
      bson_int32? ? Int32::BSON_TYPE : (bson_int64? ? Int64::BSON_TYPE : out_of_range!)
    end

    # Get the integer as encoded BSON.
    #
    # @example Get the integer as encoded BSON.
    #   1024.to_bson
    #
    # @return [ BSON::ByteBuffer ] The buffer with the encoded object.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
      if bson_int32?
        buffer.put_int32(self)
      elsif bson_int64?
        buffer.put_int64(self)
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

    # Convert the integer to a BSON string key.
    #
    # @example Convert the integer to a BSON key string.
    #   1.to_bson_key
    #
    # @param [ true, false ] validating_keys If BSON should validate the key.
    #
    # @return [ String ] The string key.
    #
    # @since 2.0.0
    def to_bson_key(validating_keys = Config.validating_keys?)
      self
    end

    # Converts this object to a representation directly serializable to
    # Extended JSON (https://github.com/mongodb/specifications/blob/master/source/extended-json.rst).
    #
    # This method returns the integer itself if relaxed representation is
    # requested, otherwise a $numberInt hash if the value fits in 32 bits
    # and a $numberLong otherwise. Regardless of which representation is
    # requested, a value that does not fit in 64 bits raises RangeError.
    #
    # @option opts [ nil | :relaxed | :legacy ] :mode Serialization mode
    #   (default is canonical extended JSON)
    #
    # @return [ Hash | Integer ] The extended json representation.
    def as_extended_json(**options)
      # The behavior of native integers' serialization to extended json is
      # not specified. Following our bson serialization logic in this file,
      # produce explicit $numberInt or $numberLong, choosing $numberInt if
      # the integer fits in 32 bits. In Ruby integers can be arbitrarily
      # big; integers that do not fit into 64 bits raise an error as we do not
      # want to silently perform an effective type conversion of integer ->
      # decimal.

      unless bson_int64?
        raise RangeError, "Integer #{self} is too big to be represented as a MongoDB integer"
      end

      if options[:mode] == :relaxed || options[:mode] == :legacy
        self
      elsif bson_int32?
        {'$numberInt' => to_s}
      else
        {'$numberLong' => to_s}
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
