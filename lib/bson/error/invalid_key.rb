# frozen_string_literal: true
# rubocop:todo all

module BSON
  class Error

    # Raised when trying to serialize an object into a key.
    class InvalidKey < Error

      # Instantiate the exception.
      #
      # @example Instantiate the exception.
      #   BSON::Object::InvalidKey.new(object)
      #
      # @param [ Object ] object The object that was meant for the key.
      #
      # @api private
      def initialize(object)
        super("#{object.class} instances are not allowed as keys in a BSON document.")
      end
    end
  end
end

