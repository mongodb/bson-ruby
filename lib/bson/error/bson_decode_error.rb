# frozen_string_literal: true
# rubocop:todo all

module BSON
  class Error

    # Exception raised when BSON decoding fails.
    class BSONDecodeError < Error
    end
  end
end
