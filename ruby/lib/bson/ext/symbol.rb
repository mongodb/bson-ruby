# encoding: utf-8
module BSON
  module Ext

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
      BSON_TYPE = 14.chr.freeze

      # Get the BSON single byte type for a symbol.
      #
      # @example Get the bson type.
      #   :test.bson_type
      #
      # @return [ Symbol ] 0x0E.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def bson_type
        BSON_TYPE
      end

      # Get the symbol as encoded BSON.
      #
      # @example Get the symbol as encoded BSON.
      #   :test.to_bson
      #
      # @return [ Symbol ] The encoded symbol.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def to_bson
        to_s.to_bson
      end

      # Get the symbol as an encoded C symbol.
      #
      # @example Get the symbol as an encoded C symbol.
      #   "test".to_bson_cstring
      #
      # @return [ Symbol ] The encoded symbol.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def to_bson_cstring
        to_s.to_bson_cstring
      end
    end

    # Enrich the core Symbol class with this module.
    #
    # @since 2.0.0
    ::Symbol.send(:include, Symbol)
  end
end
