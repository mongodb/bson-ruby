# encoding: utf-8
module BSON
  module Ext

    # Injects behaviour for encoding and decoding false values to and from
    # raw bytes as specified by the BSON spec.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    module FalseClass

      # A boolean is type 0x08 in the BSON spec.
      #
      # @since 2.0.0
      BSON_TYPE = 8.chr.freeze

      # Get the BSON single byte type for a boolean.
      #
      # @example Get the bson type.
      #   false.bson_type
      #
      # @return [ String ] 0x08.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def bson_type
        BSON_TYPE
      end

      # Get the false boolean as encoded BSON.
      #
      # @example Get the false boolean as encoded BSON.
      #   false.to_bson
      #
      # @return [ String ] The encoded string.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def to_bson
        NULL_BYTE
      end

      # Register this type when the module is loaded.
      #
      # @since 2.0.0
      Registry.register(BSON_TYPE, ::FalseClass)
    end

    # Enrich the core FalseClass class with this module.
    #
    # @since 2.0.0
    ::FalseClass.send(:include, FalseClass)
  end
end
