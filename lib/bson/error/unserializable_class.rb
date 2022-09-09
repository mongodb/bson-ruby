# frozen_string_literal: true

module BSON
  class Error

    # Exception raised when serializing an Array or Hash to BSON and an
    # array or hash element is of a class that does not define how to serialize
    # itself to BSON.
    class UnserializableClass < Error
    end
  end
end
