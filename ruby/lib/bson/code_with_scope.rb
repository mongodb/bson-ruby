# encoding: utf-8
module BSON

  # Represents a code with scope, which is a wrapper around javascript code
  # with variable scope provided.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  class CodeWithScope
    include Encodable

    # A code with scope is type 0x0F in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 15.chr.freeze

    # @!attribute javascript
    #   @return [ String ] The javascript code.
    #   @since 2.0.0
    # @!attribute scope
    #   @return [ Hash ] The variable scope.
    #   @since 2.0.0
    attr_reader :javascript, :scope

    # Determine if this code with scope object is equal to another object.
    #
    # @example Check the code with scope equality.
    #   code_with_scope == other
    #
    # @param [ Object ] other The object to compare against.
    #
    # @return [ true, false ] If the objects are equal.
    #
    # @since 2.0.0
    def ==(other)
      return false unless other.is_a?(CodeWithScope)
      javascript == other.javascript && scope == other.scope
    end

    # Instantiate the new code with scope.
    #
    # @example Instantiate the code with scope.
    #   BSON::CodeWithScope.new("this.value = name", name: "sid")
    #
    # @param [ String ] javascript The javascript code.
    # @param [ Hash ] scope The variable scope.
    #
    # @since 2.0.0
    def initialize(javascript, scope = {})
      @javascript = javascript
      @scope = scope
    end

    # Encode the javascript code with scope.
    #
    # @example Encode the code with scope.
    #   code_with_scope.to_bson
    #
    # @return [ String ] The encoded string.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson
      encode_bson_with_placeholder do |encoded|
        encoded << javascript.to_bson << scope.to_bson
      end
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, self)
  end
end
