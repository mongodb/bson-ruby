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
    BSON_TYPE = ::String.new(14.chr, encoding: BINARY).freeze

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
      buffer.put_symbol(self)
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
      if validating_keys
        raise BSON::String::IllegalKey.new(self) if BSON::String::ILLEGAL_KEY =~ self
      end
      self
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

    # Converts this object to a representation directly serializable to
    # Extended JSON (https://github.com/mongodb/specifications/blob/master/source/extended-json.rst).
    #
    # @option options [ true | false ] :relaxed Whether to produce relaxed
    #   extended JSON representation.
    #
    # @return [ Hash ] The extended json representation.
    def as_extended_json(**options)
      { "$symbol" => to_s }
    end

    class Raw
      # Create a BSON Symbol
      #
      # @param [ String | Symbol ] str_or_sym The symbol represented by this
      #   object. Can be specified as a Symbol or a String.
      #
      # @see http://bsonspec.org/#/specification
      def initialize(str_or_sym)
        unless str_or_sym.is_a?(String) || str_or_sym.is_a?(Symbol)
          raise ArgumentError, "BSON::Symbol::Raw must be given a symbol or a string, not #{str_or_sym}"
        end

        @symbol = str_or_sym.to_sym
      end

      # Get the underlying symbol as a Ruby symbol.
      #
      # @return [ Symbol ] The symbol represented by this BSON object.
      def to_sym
        @symbol
      end

      # Get the underlying symbol as a Ruby string.
      #
      # @return [ String ] The symbol as a string.
      def to_s
        @symbol.to_s
      end

      # Check equality of the raw bson symbol against another.
      #
      # @param [ Object ] other The object to check against.
      #
      # @return [ true, false ] If the objects are equal.
      def ==(other)
        return false unless other.is_a?(Raw)
        to_sym == other.to_sym
      end
      alias :eql? :==

      # Get the symbol as encoded BSON.
      #
      # @raise [ EncodingError ] If the symbol is not UTF-8.
      #
      # @return [ BSON::ByteBuffer ] The buffer with the encoded object.
      #
      # @see http://bsonspec.org/#/specification
      def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
        buffer.put_string(to_s)
      end

      def bson_type
        Symbol::BSON_TYPE
      end

      # Converts this object to a representation directly serializable to
      # Extended JSON (https://github.com/mongodb/specifications/blob/master/source/extended-json.rst).
      #
      # This method returns the integer value if relaxed representation is
      # requested, otherwise a $numberLong hash.
      #
      # @option options [ true | false ] :relaxed Whether to produce relaxed
      #   extended JSON representation.
      #
      # @return [ Hash | Integer ] The extended json representation.
      def as_extended_json(**options)
        {'$symbol' => to_s}
      end
    end

    module ClassMethods

      # Deserialize a symbol from BSON.
      #
      # @param [ ByteBuffer ] buffer The byte buffer.
      #
      # @option options [ nil | :bson ] :mode Decoding mode to use.
      #
      # @return [ Symbol | BSON::Symbol::Raw ] The decoded symbol.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def from_bson(buffer, **options)
        sym = buffer.get_string.intern

        if options[:mode] == :bson
          Raw.new(sym)
        else
          sym
        end
      end
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry::MAPPINGS[BSON_TYPE.ord] = ::Symbol
  end

  # Enrich the core Symbol class with this module.
  #
  # @since 2.0.0
  ::Symbol.send(:include, Symbol)
  ::Symbol.send(:extend, Symbol::ClassMethods)
end
