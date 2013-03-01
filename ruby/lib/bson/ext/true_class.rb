# encoding: utf-8
module BSON
  module Ext

    # Injects behaviour for encoding and decoding true values to and from
    # raw bytes as specified by the BSON spec.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    module TrueClass

      # A boolean is type 0x08 in the BSON spec.
      #
      # @since 2.0.0
      BSON_TYPE = 8.chr.freeze

      # Get the true boolean as encoded BSON.
      #
      # @example Get the true boolean as encoded BSON.
      #   true.to_bson
      #
      # @return [ String ] The encoded string.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def to_bson
        1.chr
      end
    end

    # Enrich the core TrueClass class with this module.
    #
    # @since 2.0.0
    ::TrueClass.send(:include, TrueClass)
  end
end
