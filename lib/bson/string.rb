# -*- coding: utf-8 -*-
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

  # Injects behaviour for encoding and decoding string values to and from
  # raw bytes as specified by the BSON spec.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module String
    include Encodable

    # A string is type 0x02 in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 2.chr.force_encoding(BINARY).freeze

    # Get the string as encoded BSON.
    #
    # @example Get the string as encoded BSON.
    #   "test".to_bson
    #
    # @raise [ EncodingError ] If the string is not UTF-8.
    #
    # @return [ String ] The encoded string.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson(encoded = ''.force_encoding(BINARY))
      encode_with_placeholder_and_null(STRING_ADJUST, encoded) do |encoded|
        to_bson_string(encoded)
      end
    end

    # Get the string as a BSON key name encoded C string with checking for special characters.
    #
    # @example Get the string as key name.
    #   "test".to_bson_key
    #
    # @raise [ EncodingError ] If the string is not UTF-8.
    #
    # @return [ String ] The encoded string.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson_key(encoded = ''.force_encoding(BINARY))
      to_bson_cstring(encoded)
    end

    # Get the string as an encoded C string.
    #
    # @example Get the string as an encoded C string.
    #   "test".to_bson_cstring
    #
    # @raise [ EncodingError ] If the string is not UTF-8.
    #
    # @return [ String ] The encoded string.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson_cstring(encoded = ''.force_encoding(BINARY))
      check_for_illegal_characters!
      to_bson_string(encoded) << NULL_BYTE
    end

    # Convert the string to an object id. This will only work for strings of size
    # 12.
    #
    # @example Convert the string to an object id.
    #   string.to_bson_object_id
    #
    # @note This is used for repairing legacy bson data.
    #
    # @raise [ InvalidObjectId ] If the string is not 12 elements.
    #
    # @return [ String ] The raw object id bytes.
    #
    # @since 2.0.0
    def to_bson_object_id
      ObjectId.repair(self)
    end

    # Convert the string to a UTF-8 string then force to binary. This is so
    # we get errors for strings that are not UTF-8 encoded.
    #
    # @example Convert to valid BSON string.
    #   "Straße".to_bson_string
    #
    # @raise [ EncodingError ] If the string is not UTF-8.
    #
    # @return [ String ] The binary string.
    #
    # @since 2.0.0
    def to_bson_string(encoded = ''.force_encoding(BINARY))
      begin
        to_utf8_binary(encoded)
      rescue EncodingError
        data = dup.force_encoding(UTF8)
        raise unless data.valid_encoding?
        encoded << data.force_encoding(BINARY)
      end
    end

    # Convert the string to a hexidecimal representation.
    #
    # @example Convert the string to hex.
    #   "\x01".to_hex_string
    #
    # @return [ String ] The string as hex.
    #
    # @since 2.0.0
    def to_hex_string
      unpack("H*")[0]
    end

    # Take the binary string and return a UTF-8 encoded string.
    #
    # @example Convert from a BSON string.
    #   "\x00".from_bson_string
    #
    # @raise [ EncodingError ] If the string is not UTF-8.
    #
    # @return [ String ] The UTF-8 string.
    #
    # @since 2.0.0
    def from_bson_string
      force_encoding(UTF8)
    end

    # Set four bytes for int32 in a binary string and return it.
    #
    # @example Set int32 in a BSON string.
    #   "".set_int32(pos, int32)
    #
    # @param [ Fixnum ] The position to set.
    # @param [ Fixnum ] The int32 value.
    #
    # @return [ String ] The binary string.
    #
    # @since 2.0.0
    def set_int32(pos, int32)
      self[pos, 4] = [ int32 ].pack(Int32::PACK)
    end

    private

    def to_utf8_binary(encoded)
      encoded << encode(UTF8).force_encoding(BINARY)
    end

    module ClassMethods

      # Deserialize a string from BSON.
      #
      # @param [ BSON ] bson The bson representing a string.
      #
      # @return [ Regexp ] The decoded string.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def from_bson(bson)
        bson.read(Int32.from_bson(bson)).from_bson_string.chop!
      end
    end

    private

    def check_for_illegal_characters!
      if include?(NULL_BYTE)
        raise(ArgumentError, "Illegal C-String '#{self}' contains a null byte.")
      end
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, ::String)
  end

  # Enrich the core String class with this module.
  #
  # @since 2.0.0
  ::String.send(:include, String)
  ::String.send(:extend, String::ClassMethods)
end
