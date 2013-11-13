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

  # Injects behaviour for encoding and decoding arrays to
  # and from raw bytes as specified by the BSON spec.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module Array
    include Encodable

    # An array is type 0x04 in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 4.chr.force_encoding(BINARY).freeze

    # Get the array as encoded BSON.
    #
    # @example Get the array as encoded BSON.
    #   [ 1, 2, 3 ].to_bson
    #
    # @note Arrays are encoded as documents, where the index of the value in
    #   the array is the actual key.
    #
    # @return [ String ] The encoded string.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson(encoded = ''.force_encoding(BINARY))
      encode_with_placeholder_and_null(BSON_ADJUST, encoded) do |encoded|
        each_with_index do |value, index|
          encoded << value.bson_type
          index.to_bson_key(encoded)
          value.to_bson(encoded)
        end
      end
    end

    # Convert the array to an object id. This will only work for arrays of size
    # 12 where the elements are all strings.
    #
    # @example Convert the array to an object id.
    #   array.to_bson_object_id
    #
    # @note This is used for repairing legacy bson data.
    #
    # @raise [ InvalidObjectId ] If the array is not 12 elements.
    #
    # @return [ String ] The raw object id bytes.
    #
    # @since 2.0.0
    def to_bson_object_id
      ObjectId.repair(self) { pack("C*") }
    end

    module ClassMethods

      # Deserialize the array from BSON.
      #
      # @param [ BSON ] bson The bson representing an array.
      #
      # @return [ Array ] The decoded array.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def from_bson(bson)
        array = new
        bson.read(4) # throw away the length
        while (type = bson.readbyte.chr) != NULL_BYTE
          bson.gets(NULL_BYTE)
          array << BSON::Registry.get(type).from_bson(bson)
        end
        array
      end
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, ::Array)
  end

  # Enrich the core Array class with this module.
  #
  # @since 2.0.0
  ::Array.send(:include, Array)
  ::Array.send(:extend, Array::ClassMethods)
end
