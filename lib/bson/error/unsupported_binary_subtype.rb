# frozen_string_literal: true
# rubocop:todo all

module BSON
  class Error

    # Exception raised when decoding BSON and the data contains an
    # unsupported binary subtype.
    class UnsupportedBinarySubtype < Error
    end
  end
end
