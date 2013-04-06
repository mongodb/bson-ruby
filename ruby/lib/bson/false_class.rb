# encoding: utf-8
module BSON

  # Injects behaviour for encoding and decoding false values to and from
  # raw bytes as specified by the BSON spec.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module FalseClass

    # A false value in the BSON spec is 0x00.
    #
    # @since 2.0.0
    FALSE_BYTE = 0.chr.force_encoding(BINARY).freeze

    # The BSON type for false values is the general boolean type of 0x08.
    #
    # @example Get the bson type.
    #   false.bson_type
    #
    # @return [ String ] The character 0x08.
    #
    # @since 2.0.0
    def bson_type
      Boolean::BSON_TYPE
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
    def to_bson(encoded = ''.force_encoding(BINARY))
      encoded << FALSE_BYTE
    end
  end

  # Enrich the core FalseClass class with this module.
  #
  # @since 2.0.0
  ::FalseClass.send(:include, FalseClass)
end
