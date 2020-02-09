module BSON
  # Base exception class for all BSON-related errors.
  #
  # @note Many existing exceptions raised by bson-ruby do not derive from
  #   this base class. This will change in the next major version (5.0).
  class Error < StandardError

    # Exception raised when Extended JSON parsing fails.
    class ExtJSONParseError < Error
    end

    # Exception raised when decoding BSON and the data contains an
    # unsupported binary subtype.
    class UnsupportedBinarySubtype < Error
    end
  end
end
