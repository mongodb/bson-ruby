# encoding: utf-8
module BSON

  # Represents the Undefined BSON type
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  class Undefined

    # Undefined is type 0x06 in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 6.chr.force_encoding(BINARY).freeze

    # Encode the Undefined field - has no value since it only needs the type 
    # and field name when being encoded.
    #
    # @example Encode the undefined value.
    #   Undefined.to_bson
    #
    # @return [ String ] An empty string.
    #
    # @since 2.0.0
    def to_bson
      NO_VALUE
    end

    # Deserialize undefined BSON type from BSON.
    #
    # @param [ BSON ] bson The encoded undefined value.
    #
    # @return [ Undefined ] The decoded undefined value.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def self.from_bson(bson)
      self
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, self)
  end
end
