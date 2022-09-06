# frozen_string_literal: true

module BSON
  class Error

    # Raised when validating keys and a key is illegal in MongoDB
    class IllegalKey < RuntimeError

      # Instantiate the exception.
      #
      # @example Instantiate the exception.
      #   BSON::Error::IllegalKey.new(string)
      #
      # @param [ String ] string The illegal string.
      def initialize(string)
        super("'#{string}' is an illegal key in MongoDB. Keys may not start with '$' or contain a '.'.")
      end
    end
  end
end
