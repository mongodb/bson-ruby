# encoding: utf-8
module BSON

  # Represents an element in the BSON specification, where a document has a
  # sequence of elements.
  #
  # @since 2.0.0
  class Element

    # @!attribute field
    #   @return [ String ] The field name.
    #   @since 2.0.0
    #
    # @!attribute value
    #   @return [ Object ] The object.
    #   @since 2.0.0
    attr_reader :field, :value

    # Initialize the new element.
    #
    # @example Initialize the new element.
    #   BSON::Element.new("name", "test")
    #
    # @param [ String ] field The field name.
    # @param [ Object ] value The value.
    #
    # @since 2.0.0
    def initialize(field, value)
      @field, @value = field, value
    end

    # Encode the element to its raw BSON bytes.
    #
    # @example Encode the element to BSON.
    #   element.to_bson
    #
    # @return [ String ] The encoded element.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson(encoded = ''.force_encoding(BINARY))
      encoded << value.bson_type << field.to_bson_cstring
      value.to_bson(encoded)
    end
  end
end
