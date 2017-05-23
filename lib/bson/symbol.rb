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

  # Injects behaviour for encoding and decoding symbol values to and from
  # raw bytes as specified by the BSON spec.
  #
  # @note Symbols are deprecated in the BSON spec, but they are still
  #   currently supported here for backwards compatibility.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module Symbol

    # A symbol is type 0x0E in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 14.chr.force_encoding(BINARY).freeze

    # Key for this type when converted to extended json.
    #
    # @since 5.1.0
    EXTENDED_JSON_KEY = '$symbol'.freeze

    # Symbols are serialized as strings as symbols are now removed from the
    # BSON specification. Therefore the bson_type when serializing must be a
    # string.
    #
    # @example Get the BSON type for the symbol.
    #   :test.bson_type
    #
    # @return [ String ] The single byte BSON type.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 4.0.0
    def bson_type
      String::BSON_TYPE
    end

    # Get the symbol as encoded BSON.
    #
    # @example Get the symbol as encoded BSON.
    #   :test.to_bson
    #
    # @return [ BSON::ByteBuffer ] The buffer with the encoded object.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
      to_s.to_bson(buffer)
    end

    # Get the symbol as a BSON key name encoded C symbol.
    #
    # @example Get the symbol as a key name.
    #   :test.to_bson_key
    #
    # @return [ String ] The encoded symbol as a BSON key.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson_key(validating_keys = Config.validating_keys?)
      to_s.to_bson_key(validating_keys)
    end

    # Converts the symbol to a normalized key in a BSON document.
    #
    # @example Convert the symbol to a normalized key.
    #   :test.to_bson_normalized_key
    #
    # @return [ String ] The symbol as a non interned string.
    #
    # @since 3.0.0
    def to_bson_normalized_key
      to_s
    end

    # Get the symbol as JSON hash data, complying with the Extended JSON spec.
    #
    # @example Get the symbol as an Extended JSON hash.
    #   symbol.as_extended_json
    #
    # @return [ Hash ] The symbol as an Extended JSON hash.
    #
    # @since 5.1.0
    def as_extended_json
      { EXTENDED_JSON_KEY => to_s }
    end

    # Get the extended JSON representation of this object.
    #
    # @example Convert the object to extended JSON
    #   symbol.to_extended_json
    #
    # @return [ String ] The object as extended JSON.
    #
    # @since 5.1.0
    def to_extended_json(*args)
      as_extended_json.to_json(*args)
    end

    module ClassMethods

      # Deserialize a symbol from BSON.
      #
      # @param [ ByteBuffer ] buffer The byte buffer.
      #
      # @return [ Regexp ] The decoded symbol.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def from_bson(buffer)
        buffer.get_string.intern
      end

      # Create a Symbol object from JSON data.
      #
      # @example Instantiate a symbol from JSON hash data.
      #   ::Symbol.json_create(hash)
      #
      # @param [ Hash ] json The json data.
      #
      # @return [ Symbol ] The new Symbol object.
      #
      # @since 5.1.0
      def json_create(json)
        json[EXTENDED_JSON_KEY].to_sym
      end
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry::MAPPINGS.store(BSON_TYPE, ::Symbol)
    ExtendedJSON.register(::Symbol, EXTENDED_JSON_KEY)
  end

  # Enrich the core Symbol class with this module.
  #
  # @since 2.0.0
  ::Symbol.send(:include, Symbol)
  ::Symbol.send(:extend, Symbol::ClassMethods)
end
