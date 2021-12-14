# frozen_string_literal: true
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

    # Exception raised when BSON decoding fails.
    class BSONDecodeError < Error
    end

    # Exception raised when serializing an Array or Hash to BSON and an
    # array or hash element is of a class that does not define how to serialize
    # itself to BSON.
    class UnserializableClass < Error
    end

    # Exception raised when there is an invalid argument passed into the
    # constructor of regexp object. This includes when the argument contains
    # a null byte.
    class InvalidRegexpPattern < Error
    end
  end
end
