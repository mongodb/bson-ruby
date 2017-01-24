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

  # Represents the Undefined BSON type
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  class Undefined
    include Specialized

    # Undefined is type 0x06 in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 6.chr.force_encoding(BINARY).freeze

    # Key for this type when converted to extended json.
    #
    # @since 5.1.0
    EXTENDED_JSON_KEY = '$undefined'.freeze

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

    # Get the undefined object as JSON hash data, complying with the Extended JSON spec.
    #
    # @example Get the undefined object as an Extended JSON hash.
    #   undefined.as_extended_json
    #
    # @return [ Hash ] The symbol as an Extended JSON hash.
    #
    # @since 5.1.0
    def as_extended_json
      { EXTENDED_JSON_KEY => true }
    end

    # Get the extended JSON representation of this object.
    #
    # @example Convert the object to extended JSON
    #   undefined.to_extended_json
    #
    # @return [ String ] The object as extended JSON.
    #
    # @since 5.1.0
    def to_extended_json(*args)
      as_extended_json.to_json(*args)
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, self)
    BSON::ExtendedJSON.register(self, EXTENDED_JSON_KEY)
  end
end
