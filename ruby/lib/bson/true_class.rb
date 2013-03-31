# encoding: utf-8
module BSON

  # Injects behaviour for encoding and decoding true values to and from
  # raw bytes as specified by the BSON spec.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module TrueClass

    # A true value in the BSON spec is 0x01.
    #
    # @since 2.0.0
    TRUE_BYTE = 1.chr.force_encoding(BINARY).freeze

    # The BSON type for true values is the general boolean type of 0x08.
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
      TRUE_BYTE
    end
  end

  # Enrich the core TrueClass class with this module.
  #
  # @since 2.0.0
  ::TrueClass.send(:include, TrueClass)
end
