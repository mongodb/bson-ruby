# encoding: utf-8
module BSON

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

    # A false value in the BSON spec is 0x00.
    #
    # @since 2.0.0
    FALSE_BYTE = 0.chr.freeze

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
      FALSE_BYTE
    end
  end

  # Enrich the core FalseClass class with this module.
  #
  # @since 2.0.0
  ::FalseClass.send(:include, FalseClass)
end
