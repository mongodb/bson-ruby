# encoding: utf-8
module BSON
  module Ext

    # Injects behaviour for encoding and decoding time values to
    # and from raw bytes as specified by the BSON spec.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    module Time

      # A time is type 0x09 in the BSON spec.
      #
      # @since 2.0.0
      BSON_TYPE = 9.chr.freeze

      # Get the BSON single byte type for a time.
      #
      # @example Get the bson type.
      #   Time.now.to_bson
      #
      # @return [ String ] 0x09.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def bson_type
        BSON_TYPE
      end

      # Get the time as encoded BSON.
      #
      # @example Get the time as encoded BSON.
      #   Time.new(2012, 1, 1).to_bson
      #
      # @return [ String ] The encoded string.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def to_bson
        (to_f * 1000).to_i.to_bson
      end
    end

    # Enrich the core Time class with this module.
    #
    # @since 2.0.0
    ::Time.send(:include, Time)
  end
end
