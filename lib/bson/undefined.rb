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

  # Represents the Undefined BSON type
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  class Undefined

    # Undefined is type 0x06 in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 6.chr.force_encoding(BINARY).freeze

    # Determine if undefined is equal to another object.
    #
    # @example Check undefined equality.
    #   BSON::Undefined.new == object
    #
    # @param [ Object ] other The object to check against.
    #
    # @return [ true, false ] If the objects are equal.
    #
    # @since 2.0.0
    def ==(other)
      self.class == other.class
    end

    # Encode the Undefined field - has no value since it only needs the type
    # and field name when being encoded.
    #
    # @example Encode the undefined value.
    #   Undefined.to_bson
    #
    # @return [ String ] An empty string.
    #
    # @since 2.0.0
    def to_bson(encoded = ''.force_encoding(BINARY))
      encoded
    end

    # Deserialize undefined BSON type from BSON.
    #
    # @param [ BSON ] bson The encoded undefined value.
    #
    # @return [ Undefined ] The decoded undefined value.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def self.from_bson(bson)
      new
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, self)
  end
end
