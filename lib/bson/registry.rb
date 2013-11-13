# Copyright (C) 2009-2013 MongoDB Inc.
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
    def get(byte)
      MAPPINGS.fetch(byte)
    end

    # Register the Ruby type for the corresponding single byte.
    #
    # @example Register the type.
    #   BSON::Registry.register("\x01", Float)
    #
    # @param [ String ] byte The single byte.
    # @param [ Class ] The class the byte maps to.
    #
    # @return [ Class ] The class.
    #
    # @since 2.0.0
    def register(byte, type)
      MAPPINGS.store(byte, type)
      define_type_reader(type)
    end

    private

    def define_type_reader(type)
      type.module_eval <<-MOD
        def bson_type; BSON_TYPE; end
      MOD
    end
  end
end
