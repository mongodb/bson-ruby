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

  # Injects behaviour for encoding and decoding arrays to
  # and from raw bytes as specified by the BSON spec.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module Array

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
    # @return [ BSON::ByteBuffer ] The buffer with the encoded object.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
      position = buffer.length
      buffer.put_int32(0)
      each_with_index do |value, index|
        buffer.put_byte(value.bson_type)
        buffer.put_cstring(index.to_s)
        value.to_bson(buffer, validating_keys)
      end
      buffer.put_byte(NULL_BYTE)
      buffer.replace_int32(position, buffer.length - position)
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

    # Converts the array to a normalized value in a BSON document.
    #
    # @example Convert the array to a normalized value.
    #   array.to_bson_normalized_value
    #
    # @return [ Array ] The normalized array.
    #
    # @since 3.0.0
    def to_bson_normalized_value
      map { |value| value.to_bson_normalized_value }
    end

    module ClassMethods

      # Deserialize the array from BSON.
      #
      # @param [ ByteBuffer ] buffer The byte buffer.
      #
      # @return [ Array ] The decoded array.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def from_bson(buffer)
        array = new
        buffer.get_int32 # throw away the length
        while (type = buffer.get_byte) != NULL_BYTE
          buffer.get_cstring
          array << BSON::Registry.get(type).from_bson(buffer)
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
