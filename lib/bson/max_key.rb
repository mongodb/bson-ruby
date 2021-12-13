# frozen_string_literal: true
# Copyright (C) 2009-2020 MongoDB Inc.
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

  # Represents a $maxKey type, which compares less than any other value in the
  # specification.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  class MaxKey
    include Comparable
    include JSON
    include Specialized

    # A $maxKey is type 0x7F in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = ::String.new(127.chr, encoding: BINARY).freeze

    # Constant for always evaluating greater in a comparison.
    #
    # @since 2.0.0
    GREATER = 1

    # When comparing a max key with any other object, the max key will always
    # be greater.
    #
    # @example Compare with another object.
    #   max_key <=> 1000
    #
    # @param [ Object ] other The object to compare against.
    #
    # @return [ Integer ] Always 1.
    #
    # @since 2.0.0
    def <=>(other)
      GREATER
    end

    # Get the max key as JSON hash data.
    #
    # @example Get the max key as a JSON hash.
    #   max_key.as_json
    #
    # @return [ Hash ] The max key as a JSON hash.
    #
    # @since 2.0.0
    # @deprecated Use as_extended_json instead.
    def as_json(*args)
      as_extended_json
    end

    # Converts this object to a representation directly serializable to
    # Extended JSON (https://github.com/mongodb/specifications/blob/master/source/extended-json.rst).
    #
    # @option opts [ nil | :relaxed | :legacy ] :mode Serialization mode
    #   (default is canonical extended JSON)
    #
    # @return [ Hash ] The extended json representation.
    def as_extended_json(**options)
      { "$maxKey" => 1 }
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, self)
  end
end
