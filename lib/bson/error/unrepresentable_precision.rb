# frozen_string_literal: true
# rubocop:todo all

module BSON
  class Error

    # Raised when the significand provided is outside the valid range.
    class UnrepresentablePrecision < Error

      # Get the custom error message for the exception.
      #
      # @return [ String ] The error message.
      def message
        'The value contains too much precision for Decimal128 representation'
      end
    end
  end
end

