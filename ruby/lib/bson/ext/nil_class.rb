# encoding: utf-8
module BSON
  module Ext

    # Injects behaviour for encoding and decoding nil values to and from
    # raw bytes as specified by the BSON spec.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    module NilClass

      # A nil is type 0x0A in the BSON spec.
      #
      # @since 2.0.0
      BSON_TYPE = 10.chr.freeze

      # Get the BSON single byte type for a nil.
      #
      # @example Get the bson type.
      #   nil.bson_type
      #
      # @return [ String ] 0x0A.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def bson_type
        BSON_TYPE
      end

      # Get the nil as encoded BSON.
      #
      # @example Get the nil as encoded BSON.
      #   nil.to_bson
      #
      # @return [ String ] An empty string.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def to_bson
        NO_VALUE
      end

      # Register this type when the module is loaded.
      #
      # @since 2.0.0
      Registry.register(BSON_TYPE, ::NilClass)
    end

    # Enrich the core NilClass class with this module.
    #
    # @since 2.0.0
    ::NilClass.send(:include, NilClass)
  end
end
