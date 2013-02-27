# encoding: utf-8
module BSON

  # Represents a code type, which is a wrapper around javascript code.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  class Code

    # A code is type 0x0D in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 13.chr.freeze

    # Get the BSON single byte type for javascript code.
    #
    # @example Get the bson type.
    #   code.bson_type
    #
    # @return [ String ] 0x0D.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def bson_type
      BSON_TYPE
    end

    # Encode the javascript code.
    #
    # @example Encode the code.
    #   code.to_bson
    #
    # @return [ String ] An empty string.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson
    end
  end
end
