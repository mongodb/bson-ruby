# frozen_string_literal: true
# rubocop:todo all

module BSON
  class Error

    # Raised when providing an invalid type to the Binary.
    class InvalidBinaryType < Error

      # @return [ Object ] The invalid type.
      attr_reader :type

      # Instantiate the new error.
      #
      # @example Instantiate the error.
      #   InvalidBinaryType.new(:error)
      #
      # @param [ Object ] type The invalid type.
      #
      # @api private
      def initialize(type)
        @type = type
      end

      # Get the custom error message for the exception.
      #
      # @example Get the message.
      #   error.message
      #
      # @return [ String ] The error message.
      def message
        "#{type.inspect} is not a valid binary type. " +
          "Please use one of #{BSON::Binary::SUBTYPES.keys.map(&:inspect).join(", ")}."
      end
    end
  end
end
