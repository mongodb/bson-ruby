# Copyright (C) 2009-2014 MongoDB Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module BSON

  # Provides constant values for each to the BSON types and mappings from raw
  # bytes back to these types.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module Registry
    extend self

    # A Mapping of all the BSON types to their corresponding Ruby classes.
    #
    # @since 2.0.0
    MAPPINGS = {}

    # Get the class for the single byte identifier for the type in the BSON
    # specification.
    #
    # @example Get the type for the byte.
    #   BSON::Registry.get("\x01")
    #
    # @return [ Class ] The corresponding Ruby class for the type.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def get(byte, field = nil)
      if type = MAPPINGS[byte]
        type
      else
        handle_unsupported_type!(byte, field)
      end
    end

    # Register the Ruby type for the corresponding single byte.
    #
    # @example Register the type.
    #   BSON::Registry.register("\x01", Float)
    #
    # @param [ String ] byte The single byte.
    # @param [ Class ] type The class the byte maps to.
    #
    # @return [ Class ] The class.
    #
    # @since 2.0.0
    def register(byte, type)
      MAPPINGS.store(byte, type)
      define_type_reader(type)
    end

    # Raised when trying to get a type from the registry that doesn't exist.
    #
    # @since 4.1.0
    class UnsupportedType < RuntimeError; end

    private

    def define_type_reader(type)
      type.module_eval <<-MOD
        def bson_type; BSON_TYPE; end
      MOD
    end

    def handle_unsupported_type!(byte, field)
      message = "Detected unknown BSON type #{byte.inspect} "
      message += (field ? "for fieldname \"#{field}\". " : "in array. ")
      message +="Are you using the latest BSON version?"
      raise UnsupportedType.new(message)
    end
  end
end
