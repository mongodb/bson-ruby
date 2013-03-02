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
    BSON_TYPE = 13.chr.force_encoding(BINARY).freeze

    # @!attribute javascript
    #   @return [ String ] The javascript code.
    #   @since 2.0.0
    attr_reader :javascript

    # Determine if this code object is equal to another object.
    #
    # @example Check the code equality.
    #   code == other
    #
    # @param [ Object ] other The object to compare against.
    #
    # @return [ true, false ] If the objects are equal.
    #
    # @since 2.0.0
    def ==(other)
      return false unless other.is_a?(Code)
      javascript == other.javascript
    end

    # Instantiate the new code.
    #
    # @example Instantiate the new code.
    #   BSON::Code.new("this.value = 5")
    #
    # @param [ String ] javascript The javascript code.
    #
    # @since 2.0.0
    def initialize(javascript)
      @javascript = javascript
    end

    # Encode the javascript code.
    #
    # @example Encode the code.
    #   code.to_bson
    #
    # @return [ String ] The encoded string.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson
      raw = javascript.to_bson_string
      (raw.bytesize + 1).to_bson + javascript.to_bson_cstring
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, self)
  end
end
