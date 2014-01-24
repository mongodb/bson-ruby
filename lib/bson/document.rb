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

require "yaml"

# Since we have a custom bsondoc type for yaml serialization, we need
# to ensure that it's properly deserialized when parsed.
#
# @since 2.0.0
YAML.add_builtin_type("bsondoc") do |type, value|
  BSON::Document[value.map{ |val| val.to_a.first }]
end

module BSON

  # This module provides behaviour for serializing and deserializing entire
  # BSON documents, according to the BSON specification.
  #
  # @note The specification is: document ::= int32 e_list "\x00"
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  class Document < ::Hash

    # Get a value from the document for the provided key. Can use string or
    # symbol access, but the fastest will be to always provide a key that is of
    # the same type as the stored keys.
    #
    # @example Get an element for the key.
    #   document["field"]
    #
    # @example Get an element for the key by symbol.
    #   document[:field]
    #
    # @param [ String, Symbol ] key The key to lookup.
    #
    # @return [ Object ] The found value, or nil if none found.
    #
    # @since 2.0.0
    def [](key)
      super(key) || super(key.to_s)
    end
  end
end
