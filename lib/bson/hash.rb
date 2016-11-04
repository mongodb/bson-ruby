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

  # Injects behaviour for encoding and decoding hashes to
  # and from raw bytes as specified by the BSON spec.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module Hash

    # An hash (embedded document) is type 0x03 in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 3.chr.force_encoding(BINARY).freeze

    # Get the hash as encoded BSON.
    #
    # @example Get the hash as encoded BSON.
    #   { "field" => "value" }.to_bson
    #
    # @return [ BSON::ByteBuffer ] The buffer with the encoded object.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
      position = buffer.length
      buffer.put_int32(0)
      each do |field, value|
        buffer.put_byte(value.bson_type)
        buffer.put_cstring(field.to_bson_key(validating_keys))
        value.to_bson(buffer, validating_keys)
      end
      buffer.put_byte(NULL_BYTE)
      buffer.replace_int32(position, buffer.length - position)
    end

    # Converts the hash to a normalized value in a BSON document.
    #
    # @example Convert the hash to a normalized value.
    #   hash.to_bson_normalized_value
    #
    # @return [ BSON::Document ] The normazlied hash.
    #
    # @since 3.0.0
    def to_bson_normalized_value
      Document.new(self)
    end

    module ClassMethods

      # Deserialize the hash from BSON.
      #
      # @param [ ByteBuffer ] buffer The byte buffer.
      #
      # @return [ Array ] The decoded hash.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def from_bson(buffer)
        hash = Document.allocate
        buffer.get_int32 # Throw away the size.
        while (type = buffer.get_byte) != NULL_BYTE
          field = buffer.get_cstring
          hash.store(field, BSON::Registry.get(type, field).from_bson(buffer))
        end
        hash
      end
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, ::Hash)
  end

  # Enrich the core Hash class with this module.
  #
  # @since 2.0.0
  ::Hash.send(:include, Hash)
  ::Hash.send(:extend, Hash::ClassMethods)
end
