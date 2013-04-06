# encoding: utf-8
module BSON

  # Represents a $maxKey type, which compares less than any other value in the
  # specification.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  class MaxKey
    include Comparable
    include JSON

    # A $maxKey is type 0x7F in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 127.chr.force_encoding(BINARY).freeze

    # Constant for always evaluating greater in a comparison.
    #
    # @since 2.0.0
    GREATER = 1.freeze

    # Determine if the max key is equal to another object.
    #
    # @example Check max key equality.
    #   BSON::MaxKey.new == object
    #
    # @param [ Object ] other The object to check against.
    #
    # @return [ true, false ] If the objects are equal.
    #
    # @since 2.0.0
    def ==(other)
      self.class == other.class
    end

    # When comparing a max key with any other object, the max key will always
    # be greater.
    #
    # @example Compare with another object.
    #   max_key <=> 1000
    #
    # @param [ Object ] The object to compare against.
    #
    # @return [ Integer ] Always 1.
    #
    # @since 2.0.0
    def <=>(other)
      GREATER
    end

    # Get the max key as JSON hash data.
    #
    # @example Get the max key as a JSON hash.
    #   max_key.as_json
    #
    # @return [ Hash ] The max key as a JSON hash.
    #
    # @since 2.0.0
    def as_json(*args)
      { "$maxKey" => 1 }
    end

    # Encode the max key - has no value since it only needs the type and field
    # name when being encoded.
    #
    # @example Encode the max key value.
    #   max_key.to_bson
    #
    # @return [ String ] An empty string.
    #
    # @since 2.0.0
    def to_bson(encoded = ''.force_encoding(BINARY))
      encoded << NO_VALUE
    end

    # Deserialize MaxKey from BSON.
    #
    # @param [ BSON ] bson The encoded MaxKey.
    #
    # @return [ MaxKey ] The decoded MaxKey.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def self.from_bson(bson)
      new
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, self)
  end
end
