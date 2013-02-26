# encoding: utf-8
module BSON
  module Ext

    # Injects behaviour for encoding and decoding date values to
    # and from raw bytes as specified by the BSON spec.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    module Date

      # A date is type 0x09 in the BSON spec.
      #
      # @since 2.0.0
      BSON_TYPE = 9.chr.freeze

      # Get the BSON single byte type for a date.
      #
      # @example Get the bson type.
      #   Date.now.to_bson
      #
      # @return [ String ] 0x09.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def bson_type
        BSON_TYPE
      end

      # Get the date as encoded BSON.
      #
      # @example Get the date as encoded BSON.
      #   Date.new(2012, 1, 1).to_bson
      #
      # @return [ String ] The encoded string.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def to_bson
        to_time.to_bson
      end
    end

    # Enrich the core Date class with this module.
    #
    # @since 2.0.0
    ::Date.send(:include, Date)
  end
end
