# encoding: utf-8
module BSON
  module Ext

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
      BSON_TYPE = 4.chr.freeze

      # Get the BSON single byte type for an array.
      #
      # @example Get the bson type.
      #   [ 1, 2, 3 ].to_bson
      #
      # @return [ String ] 0x04.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def bson_type
        BSON_TYPE
      end

      # Get the array as encoded BSON.
      #
      # @example Get the array as encoded BSON.
      #   [ 1, 2, 3 ].to_bson
      #
      # @note Arrays are encoded as documents, where the index of the value in
      #   the array is the actual key.
      #
      # @return [ String ] The encoded string.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def to_bson
      end
    end

    # Enrich the core Array class with this module.
    #
    # @since 2.0.0
    ::Array.send(:include, Array)
  end
end
