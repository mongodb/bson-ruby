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
  # Injects behaviour for encoding and decoding hashes to
  # and from raw bytes as specified by the BSON spec.
  #
  # @see http://bsonspec.org/#/specification
  module Hash
    # A hash, also called an embedded document, is type 0x03 in the BSON spec.
    BSON_TYPE = ::String.new(3.chr, encoding: BINARY).freeze

    # Get the hash as encoded BSON.
    #
    # @example Get the hash as encoded BSON.
    #   { "field" => "value" }.to_bson
    #
    # @return [ BSON::ByteBuffer ] The buffer with the encoded object.
    #
    # @see http://bsonspec.org/#/specification
    def to_bson(buffer = ByteBuffer.new)
      # If the native buffer version has an optimized version, we'll call
      # it directly. Otherwise, we'll serialize the hash the hard way.
      if buffer.respond_to?(:put_hash)
        buffer.put_hash(self)
      else
        serialize_to_buffer(buffer)
      end
    end

    # Converts the hash to a normalized value in a BSON document.
    #
    # @example Convert the hash to a normalized value.
    #   hash.to_bson_normalized_value
    #
    # @return [ BSON::Document ] The normalized hash.
    def to_bson_normalized_value
      Document.new(self)
    end

    # Converts this object to a representation directly serializable to
    # Extended JSON (https://github.com/mongodb/specifications/blob/master/source/extended-json/extended-json.md).
    #
    # This method recursively invokes +as_extended_json+ with the provided
    # options on each hash value.
    #
    # @option opts [ nil | :relaxed | :legacy ] :mode Serialization mode
    #   (default is canonical extended JSON)
    #
    # @return [ Hash ] This hash converted to extended json representation.
    def as_extended_json(**options)
      transform_values { |value| value.as_extended_json(**options) }
    end

    private

    # Serialize this hash instance to the given buffer.
    #
    # @param [ ByteBuf ] buffer The buffer to receive the serialized hash.
    def serialize_to_buffer(buffer)
      position = buffer.length
      buffer.put_int32(0)
      serialize_key_value_pairs(buffer)
      buffer.put_byte(NULL_BYTE)
      buffer.replace_int32(position, buffer.length - position)
    end

    # Serialize the key/value pairs in this hash instance to the given
    # buffer.
    #
    # @param [ ByteBuf ] buffer The buffer to received the serialized
    #   key/value pairs.
    #
    # @raise [ Error::UnserializableClass ] if a value cannot be serialized
    def serialize_key_value_pairs(buffer)
      each do |field, value|
        unless value.respond_to?(:bson_type)
          raise Error::UnserializableClass,
                "Hash value for key '#{field}' does not define its BSON serialized type: #{value}"
        end

        buffer.put_byte(value.bson_type)
        key = field.to_bson_key
        serialize_key(buffer, key)
        value.to_bson(buffer)
      end
    end

    # Serialize the key/value pairs in this hash instance to the given
    # buffer.
    #
    # @param [ ByteBuf ] buffer The buffer to received the serialized
    #   key/value pairs.
    #
    # @raise [ ArgumentError ] if the string cannot be serialized
    # @raise [ EncodingError ] if the string is not a valid encoding
    def serialize_key(buffer, key)
      buffer.put_cstring(key)
    rescue ArgumentError => e
      raise ArgumentError, "Error serializing key #{key}: #{e.class}: #{e}"
    rescue EncodingError => e
      # Note this may convert exception class from a subclass of
      # EncodingError to EncodingError itself
      raise EncodingError, "Error serializing key #{key}: #{e.class}: #{e}"
    end

    # The methods to augment the Hash class with (class-level methods).
    module ClassMethods
      # Deserialize the hash from BSON.
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
      # @return [ Hash ] The decoded hash.
      #
      # @see http://bsonspec.org/#/specification
      def from_bson(buffer, **options)
        if buffer.respond_to?(:get_hash)
          buffer.get_hash(**options)
        else
          hash = parse_hash_from_buffer(buffer, **options)
          maybe_dbref(hash)
        end
      end

      private

      # If the hash looks like a DBRef, try and decode it as such. If
      # is turns out to be invalid--or if it doesn't look like a DBRef
      # to begin with--return the hash itself.
      #
      # @param [ Hash ] hash the hash to try and decode
      #
      # @return [ DBRef | Hash ] the result of decoding the hash
      def maybe_dbref(hash)
        return DBRef.new(hash) if hash['$ref'] && hash['$id']

        hash
      rescue Error::InvalidDBRefArgument
        hash
      end

      # Given a byte buffer, extract and return a hash from it.
      #
      # @param [ ByteBuf ] buffer the buffer to read data from
      # @param [ Hash ] options the keyword arguments
      #
      # @return [ Hash ] the hash parsed from the buffer
      def parse_hash_from_buffer(buffer, **options)
        hash = Document.allocate
        start_position = buffer.read_position
        expected_byte_size = buffer.get_int32

        parse_hash_contents(hash, buffer, **options)

        actual_byte_size = buffer.read_position - start_position
        return hash unless actual_byte_size != expected_byte_size

        raise Error::BSONDecodeError,
              "Expected hash to take #{expected_byte_size} bytes but it took #{actual_byte_size} bytes"
      end

      # Given an empty hash and a byte buffer, parse the key/value pairs from
      # the buffer and populate the hash with them.
      #
      # @param [ Hash ] hash the hash to populate
      # @param [ ByteBuf ] buffer the buffer to read data from
      # @param [ Hash ] options the keyword arguments
      def parse_hash_contents(hash, buffer, **options)
        while (type = buffer.get_byte) != NULL_BYTE
          field = buffer.get_cstring
          cls = BSON::Registry.get(type, field)
          value = if options.empty?
                    # Compatibility with the older Ruby driver versions which define
                    # a DBRef class with from_bson accepting a single argument.
                    cls.from_bson(buffer)
                  else
                    cls.from_bson(buffer, **options)
                  end
          hash.store(field, value)
        end
      end
    end

    # Register this type when the module is loaded.
    Registry.register(BSON_TYPE, ::Hash)
  end

  # Enrich the core Hash class with this module.
  ::Hash.include Hash
  ::Hash.extend Hash::ClassMethods
end
