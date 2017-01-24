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

require 'json/pure'

module BSON

  # Provides functionality for loading a string of Extended JSON.
  #
  # @since 5.1.0
  module ExtendedJSON

    extend self

    # A Mapping of sets of extended JSON special keys to their corresponding BSON classes.
    #
    # @since 5.1.0
    MAPPING = {}

    # Load a string of extended JSON into a Ruby hash, converting special representations
    # into the appropriate objects.
    #
    # @example Load an Extended JSON string.
    #  BSON::ExtendedJSON.load(string)
    #
    # @param [ String ] str The Extended JSON string.
    #
    # @return [ Hash ] The result of parsing the string and loading objects.
    #
    # @since 5.1.0
    def load(str)
      ::JSON.load(str, method(:load_to_bson))
    end

    # Register a set of special keys for the corresponding class.
    #
    # @example Register the class and its special extended JSON keys.
    #   BSON::ExtendedJSON.register(BSON::Binary, special_keys)
    #
    # @param [ Class ] type The class.
    # @param [ String, Array<String> ] keys The special keys.
    #
    # @since 5.1.0
    def register(type, *keys)
      MAPPING.store(keys.sort.uniq, type)
    end

    private

    def load_to_bson(element)
      if element.is_a?(Hash)
        element.each do |key, value|
          if value.is_a?(Hash) && klass = MAPPING[value.keys.sort.uniq]
            element[key] = klass.json_create(value)
          end
        end
      end
    end
  end
end
