# frozen_string_literal: true

module BSON
  class Error
    # Raised when trying to create a BSON::DBRef from an object that is an invalid DBRef.
    #
    # @api private
    class InvalidDBRefArgument < Error
    end
  end
end

