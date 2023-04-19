# frozen_string_literal: true
# rubocop:todo all

module BSON
  class Error

    # Raised when the exponent is outside the valid range.
    class InvalidDecimal128Range < Error

      # The custom error message for this error.
      #
      # @deprecated
      MESSAGE = 'Value out of range for Decimal128 representation.'

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

