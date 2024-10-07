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

# The top-level BSON module.
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
    BSON_TYPE = ::String.new(4.chr, encoding: BINARY).freeze

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
    def to_bson(buffer = ByteBuffer.new)
      if buffer.respond_to?(:put_array)
        buffer.put_array(self)
      else
        position = buffer.length
        buffer.put_int32(0)
        each_with_index do |value, index|
          unless value.respond_to?(:bson_type)
            raise Error::UnserializableClass,
                  "Array element at position #{index} does not define its BSON serialized type: #{value}"
          end

          buffer.put_byte(value.bson_type)
          buffer.put_cstring(index.to_s)
          value.to_bson(buffer)
        end
        buffer.put_byte(NULL_BYTE)
        buffer.replace_int32(position, buffer.length - position)
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
    # @raise [ BSON::Error::InvalidObjectId ] If the array is not 12 elements.
    #
    # @return [ String ] The raw object id bytes.
    #
    # @since 2.0.0
    def to_bson_object_id
      ObjectId.repair(self) { pack('C*') }
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
      map(&:to_bson_normalized_value)
    end

    # Converts this object to a representation directly serializable to
    # Extended JSON (https://github.com/mongodb/specifications/blob/master/source/extended-json/extended-json.md).
    #
    # This method recursively invokes +as_extended_json+ with the provided
    # options on each array element.
    #
    # @option opts [ nil | :relaxed | :legacy ] :mode Serialization mode
    #   (default is canonical extended JSON)
    #
    # @return [ Array ] This array converted to extended json representation.
    def as_extended_json(**options)
      map do |item|
        item.as_extended_json(**options)
      end
    end

    # Class-level methods to be added to the Array class.
    module ClassMethods
      # Deserialize the array from BSON.
      #
      # @note If the argument cannot be parsed, an exception will be raised
      #   and the argument will be left in an undefined state. The caller
      #   must explicitly call `rewind` on the buffer before trying to parse
      #   it again.
      #
      # @param [ ByteBuffer ] buffer The byte buffer.
      #
      # @option options [ nil | :bson ] :mode Decoding mode to use.
      #
      # @return [ Array ] The decoded array.
      #
      # @see http://bsonspec.org/#/specification
      def from_bson(buffer, **options)
        if buffer.respond_to?(:get_array)
          buffer.get_array(**options)
        else
          parse_array_from_buffer(buffer, **options)
        end
      end

      private

      # Parse an array from the buffer.
      #
      # @param [ ByteBuf ] buffer the buffer to read from
      # @param [ Hash ] options the optional keyword arguments
      #
      # @return [ Array ] the array that was parsed
      #
      # @raise [ BSON::Error::BSONDecodeError ] if the expected number of
      #   bytes were not read from the buffer
      def parse_array_from_buffer(buffer, **options)
        new.tap do |array|
          start_position = buffer.read_position
          expected_byte_size = buffer.get_int32
          parse_array_elements_from_buffer(array, buffer, **options)
          actual_byte_size = buffer.read_position - start_position
          if actual_byte_size != expected_byte_size
            raise Error::BSONDecodeError,
                  "Expected array to take #{expected_byte_size} bytes but it took #{actual_byte_size} bytes"
          end
        end
      end

      # Parse a sequence of array elements from the buffer.
      #
      # @param [ Array ] array the array to populate
      # @param [ ByteBuf ] buffer the buffer to read from
      # @param [ Hash ] options the optional keyword arguments
      def parse_array_elements_from_buffer(array, buffer, **options)
        while (type = buffer.get_byte) != NULL_BYTE
          buffer.get_cstring
          cls = BSON::Registry.get(type)
          value = if options.empty?
                    cls.from_bson(buffer)
                  else
                    cls.from_bson(buffer, **options)
                  end
          array << value
        end
      end
    end

    # Register this type when the module is loaded.
    Registry.register(BSON_TYPE, ::Array)
  end

  # Enrich the core Array class with this module.
  ::Array.include Array
  ::Array.extend Array::ClassMethods
end
