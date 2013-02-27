# encoding: utf-8
require "bson/code"
require "bson/max_key"
require "bson/min_key"
require "bson/timestamp"

module BSON

  # Provides constant values for each to the BSON types and mappings from raw
  # bytes back to these types.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module Types
    extend self

    # A Mapping of all the BSON types to their corresponding Ruby classes.
    #
    # @since 2.0.0
    MAPPINGS = {
      MaxKey::BSON_TYPE    => MaxKey,
      MinKey::BSON_TYPE    => MinKey,
      String::BSON_TYPE    => String,
      Timestamp::BSON_TYPE => Timestamp
    }

    # Get the class for the single byte identifier for the type in the BSON
    # specification.
    #
    # @example Get the type for the byte.
    #   BSON::Types.get("\x01")
    #
    # @return [ Class ] The corresponding Ruby class for the type.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def get(byte)
      MAPPINGS.fetch(byte)
    end
  end
end
