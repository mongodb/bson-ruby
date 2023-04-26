# frozen_string_literal: true
# rubocop:todo all

module BSON
  class Error

    # Raised when trying to create an object id with invalid data.
    class InvalidObjectId < Error; end
  end
end

