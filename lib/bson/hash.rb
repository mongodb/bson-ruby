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

  # Injects behaviour for encoding and decoding hashes to
  # and from raw bytes as specified by the BSON spec.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module Hash
    include Encodable

    # An hash (embedded document) is type 0x03 in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 3.chr.force_encoding(BINARY).freeze

    # Get the hash as encoded BSON.
    #
    # @example Get the hash as encoded BSON.
    #   { "field" => "value" }.to_bson
    #
    # @return [ String ] The encoded string.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson(encoded = ''.force_encoding(BINARY))
      encode_with_placeholder_and_null(BSON_ADJUST, encoded) do |encoded|
        each do |field, value|
          encoded << value.bson_type
          field.to_bson_key(encoded)
          value.to_bson(encoded)
        end
      end
    end

    module ClassMethods

      # Deserialize the hash from BSON.
      #
      # @param [ IO ] bson The bson representing a hash.
      #
      # @return [ Array ] The decoded hash.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def from_bson(bson)
        hash = new
        bson.read(4) # Swallow the first four bytes.
        while (type = bson.readbyte.chr) != NULL_BYTE
          field = bson.gets(NULL_BYTE).from_bson_string.chop!
          hash[field] = BSON::Registry.get(type).from_bson(bson)
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
