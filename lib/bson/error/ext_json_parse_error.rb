# frozen_string_literal: true
# rubocop:todo all

module BSON
  class Error

    # Exception raised when Extended JSON parsing fails.
    class ExtJSONParseError < Error
    end
  end
end
