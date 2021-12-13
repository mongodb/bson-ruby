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

  # Provides common behaviour for JSON serialization of objects.
  #
  # @since 2.0.0
  module JSON

    # Converting an object to JSON simply gets it's hash representation via
    # as_json, then converts it to a string.
    #
    # @example Convert the object to JSON
    #   object.to_json
    #
    # @note All types must implement as_json.
    #
    # @return [ String ] The object as JSON.
    #
    # @since 2.0.0
    def to_json(*args)
      as_json.to_json(*args)
    end
  end
end
