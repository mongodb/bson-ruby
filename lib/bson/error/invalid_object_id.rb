# frozen_string_literal: true

module BSON
  class Error

    # Raised when trying to create an object id with invalid data.
    class InvalidObjectId < Error; end
  end
end

