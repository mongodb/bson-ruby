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

  # Injects behaviour for encoding and decoding hashes to
  # and from raw bytes as specified by the BSON spec.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module Hash

    # A hash, also called an embedded document, is type 0x03 in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = ::String.new(3.chr, encoding: BINARY).freeze

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
      if buffer.respond_to?(:put_hash)
        buffer.put_hash(self, validating_keys)
      else
        position = buffer.length
        buffer.put_int32(0)
        each do |field, value|
          unless value.respond_to?(:bson_type)
            raise Error::UnserializableClass, "Hash value for key '#{field}' does not define its BSON serialized type: #{value}"
          end
          buffer.put_byte(value.bson_type)
          key = field.to_bson_key(validating_keys)
          begin
            buffer.put_cstring(key)
          rescue ArgumentError => e
            raise ArgumentError, "Error serializing key #{key}: #{e.class}: #{e}"
          rescue EncodingError => e
            # Note this may convert exception class from a subclass of
            # EncodingError to EncodingError itself
            raise EncodingError, "Error serializing key #{key}: #{e.class}: #{e}"
          end
          value.to_bson(buffer, validating_keys)
        end
        buffer.put_byte(NULL_BYTE)
        buffer.replace_int32(position, buffer.length - position)
      end
    end

    # Converts the hash to a normalized value in a BSON document.
    #
    # @example Convert the hash to a normalized value.
    #   hash.to_bson_normalized_value
    #
    # @return [ BSON::Document ] The normalized hash.
    #
    # @since 3.0.0
    def to_bson_normalized_value
      Document.new(self)
    end

    # Converts this object to a representation directly serializable to
    # Extended JSON (https://github.com/mongodb/specifications/blob/master/source/extended-json.rst).
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

    module ClassMethods

      # Deserialize the hash from BSON.
      #
      # @param [ ByteBuffer ] buffer The byte buffer.
      #
      # @option options [ nil | :bson ] :mode Decoding mode to use.
      #
      # @return [ Hash ] The decoded hash.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def from_bson(buffer, **options)
        if buffer.respond_to?(:get_hash)
          buffer.get_hash(**options)
        else
          hash = Document.allocate
          start_position = buffer.read_position
          expected_byte_size = buffer.get_int32
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
          actual_byte_size = buffer.read_position - start_position
          if actual_byte_size != expected_byte_size
            raise Error::BSONDecodeError, "Expected hash to take #{expected_byte_size} bytes but it took #{actual_byte_size} bytes"
          end

          if hash['$ref'] && hash['$id']
            # We're doing implicit decoding here. If the document is an invalid
            # dbref, we should decode it as a BSON::Document.
            begin
              hash = DBRef.new(hash)
            rescue ArgumentError
            end
          end

          hash
        end
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
