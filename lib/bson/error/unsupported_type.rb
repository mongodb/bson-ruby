# frozen_string_literal: true
# rubocop:todo all

module BSON
  class Error

    # Raised when trying to get a type from the registry that doesn't exist.
    class UnsupportedType < Error; end
  end
end

