# frozen_string_literal: true
# rubocop:todo all

module BSON
  class Error
    
    # Raised when trying to create a BSON::DBRef from an object that is an invalid DBRef.
    class InvalidDBRefArgument < Error
    end
  end
end

