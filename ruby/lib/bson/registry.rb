# encoding: utf-8
module BSON

  # Provides constant values for each to the BSON types and mappings from raw
  # bytes back to these types.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module Registry
    extend self

    # A Mapping of all the BSON types to their corresponding Ruby classes.
    #
    # @since 2.0.0
    MAPPINGS = {}

    # Get the class for the single byte identifier for the type in the BSON
    # specification.
    #
    # @example Get the type for the byte.
    #   BSON::Registry.get("\x01")
    #
    # @return [ Class ] The corresponding Ruby class for the type.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def get(byte)
      MAPPINGS.fetch(byte)
    end

    # Register the Ruby type for the corresponding single byte.
    #
    # @example Register the type.
    #   BSON::Registry.register("\x01", Float)
    #
    # @param [ String ] byte The single byte.
    # @param [ Class ] The class the byte maps to.
    #
    # @return [ Class ] The class.
    #
    # @since 2.0.0
    def register(byte, type)
      MAPPINGS[byte] = type
      type.define_method(:bson_type) { byte }
    end
  end
end

