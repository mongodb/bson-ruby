# encoding: utf-8
module BSON
  module Ext

    # Injects behaviour for encoding and decoding string values to and from
    # raw bytes as specified by the BSON spec.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    module String

      # A string is type 0x02 in the BSON spec.
      #
      # @since 2.0.0
      BSON_TYPE = 2.chr.freeze

      # Get the BSON single byte type for a string.
      #
      # @example Get the bson type.
      #   "test".bson_type
      #
      # @return [ String ] 0x02.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def bson_type
        BSON_TYPE
      end

      # Get the string as encoded BSON.
      #
      # @example Get the string as encoded BSON.
      #   "test".to_bson
      #
      # @return [ String ] The encoded string.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def to_bson
        (bytesize + 1).to_bson + to_bson_cstring
      end

      # Get the string as an encoded C string.
      #
      # @example Get the string as an encoded C string.
      #   "test".to_bson_cstring
      #
      # @return [ String ] The encoded string.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def to_bson_cstring
        self + NULL_BYTE
      end

      # Register this type when the module is loaded.
      #
      # @since 2.0.0
      Registry.register(BSON_TYPE, ::String)
    end

    # Enrich the core String class with this module.
    #
    # @since 2.0.0
    ::String.send(:include, String)
  end
end
