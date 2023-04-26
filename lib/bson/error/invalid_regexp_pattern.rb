# frozen_string_literal: true
# rubocop:todo all

module BSON
  class Error

    # Exception raised when there is an invalid argument passed into the
    # constructor of regexp object. This includes when the argument contains
    # a null byte.
    class InvalidRegexpPattern < Error
    end
  end
end
