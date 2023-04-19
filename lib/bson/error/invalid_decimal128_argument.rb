# frozen_string_literal: true
# rubocop:todo all

module BSON
  class Error

    # Raised when trying to create a Decimal128 from an object that is neither a String nor a BigDecimal.
    class InvalidDecimal128Argument < Error

      # The custom error message for this error.
      MESSAGE = 'A Decimal128 can only be created from a String or BigDecimal.'

      # Get the custom error message for the exception.
      #
      # @example Get the message.
      #   error.message
      #
      # @return [ String ] The error message.
      def message
        MESSAGE
      end
    end
  end
end

