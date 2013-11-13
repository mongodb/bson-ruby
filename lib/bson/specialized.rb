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

  # Provides behaviour to special values that exist in the BSON spec that don't
  # have a native type, like $minKey and $maxKey.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module Specialized

    # Determine if the min key is equal to another object.
    #
    # @example Check min key equality.
    #   BSON::MinKey.new == object
    #
    # @param [ Object ] other The object to check against.
    #
    # @return [ true, false ] If the objects are equal.
    #
    # @since 2.0.0
    def ==(other)
      self.class == other.class
    end

    # Encode the min key - has no value since it only needs the type and field
    # name when being encoded.
    #
    # @example Encode the min key value.
    #   min_key.to_bson
    #
    # @return [ String ] An empty string.
    #
    # @since 2.0.0
    def to_bson(encoded = ''.force_encoding(BINARY))
      encoded
    end

    private

    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods

      # Deserialize MinKey from BSON.
      #
      # @param [ BSON ] bson The encoded MinKey.
      #
      # @return [ MinKey ] The decoded MinKey.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def from_bson(bson)
        new
      end
    end
  end
end
