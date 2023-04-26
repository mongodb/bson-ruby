# frozen_string_literal: true
# rubocop:todo all

module BSON
  class Error

    # Raised when trying to create a Decimal128 from a string with
    #   an invalid format.
    class InvalidDecimal128String < Error

      # The custom error message for this error.
      MESSAGE = 'Invalid string format for creating a Decimal128 object.'

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

