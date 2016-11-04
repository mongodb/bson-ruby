# -*- coding: utf-8 -*-
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

  # Injects behaviour for encoding and decoding string values to and from
  # raw bytes as specified by the BSON spec.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module String

    # A string is type 0x02 in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 2.chr.force_encoding(BINARY).freeze

    # Regex for matching illegal BSON keys.
    #
    # @since 4.1.0
    ILLEGAL_KEY = /(\A[$])|(\.)/.freeze

    # Get the string as encoded BSON.
    #
    # @example Get the string as encoded BSON.
    #   "test".to_bson
    #
    # @raise [ EncodingError ] If the string is not UTF-8.
    #
    # @return [ BSON::ByteBuffer ] The buffer with the encoded object.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
      buffer.put_string(self)
    end

    # Get the string as a BSON key name encoded C string with checking for special characters.
    #
    # @example Get the string as key name.
    #   "test".to_bson_key
    #
    # @raise [ EncodingError ] If the string is not UTF-8.
    #
    # @raise [ IllegalKey ] If validating keys and it contains a '.' or starts
    #   with '$'.
    #
    # @return [ String ] The encoded string.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson_key(validating_keys = Config.validating_keys?)
      if validating_keys
        raise IllegalKey.new(self) if ILLEGAL_KEY =~ self
      end
      self
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

    # Raised when validating keys and a key is illegal in MongoDB
    #
    # @since 4.1.0
    class IllegalKey < RuntimeError

      # Instantiate the exception.
      #
      # @example Instantiate the exception.
      #   BSON::Object::IllegalKey.new(string)
      #
      # @param [ String ] string The illegal string.
      #
      # @since 4.1.0
      def initialize(string)
        super("'#{string}' is an illegal key in MongoDB. Keys may not start with '$' or contain a '.'.")
      end
    end

    module ClassMethods

      # Deserialize a string from BSON.
      #
      # @param [ ByteBuffer ] buffer The byte buffer.
      #
      # @return [ Regexp ] The decoded string.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def from_bson(buffer)
        buffer.get_string
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
