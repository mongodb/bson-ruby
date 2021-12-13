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

  # Injects behaviour for all Ruby objects.
  #
  # @since 2.2.4
  module Object

    # Objects that don't override this method will raise an error when trying
    # to use them as keys in a BSON document. This is only overridden in String
    # and Symbol.
    #
    # @example Convert the object to a BSON key.
    #   object.to_bson_key
    #
    # @raise [ InvalidKey ] Always raises an exception.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.2.4
    def to_bson_key(validating_keys = Config.validating_keys?)
      raise InvalidKey.new(self)
    end

    # Converts the object to a normalized key in a BSON document.
    #
    # @example Convert the object to a normalized key.
    #   object.to_bson_normalized_key
    #
    # @return [ Object ] self.
    #
    # @since 3.0.0
    def to_bson_normalized_key
      self
    end

    # Converts the object to a normalized value in a BSON document.
    #
    # @example Convert the object to a normalized value.
    #   object.to_bson_normalized_value
    #
    # @return [ Object ] self.
    #
    # @since 3.0.0
    def to_bson_normalized_value
      self
    end

    # Serializes this object to Extended JSON
    # (https://github.com/mongodb/specifications/blob/master/source/extended-json.rst).
    #
    # Subclasses should override +as_extended_json+ rather than this method.
    #
    # @option opts [ nil | :relaxed | :legacy ] :mode Serialization mode
    #   (default is canonical extended JSON)
    #
    # @return [ String ] The extended json serialization.
    def to_extended_json(**options)
      as_extended_json(**options).to_json
    end

    # Converts this object to a representation directly serializable to
    # Extended JSON (https://github.com/mongodb/specifications/blob/master/source/extended-json.rst).
    #
    # Subclasses should override this method to provide custom serialization
    # to Extended JSON.
    #
    # @option options [ true | false ] :relaxed Whether to produce relaxed
    #   extended JSON representation.
    #
    # @return [ Object ] The extended json representation.
    def as_extended_json(**options)
      self
    end
  end

  # Raised when trying to serialize an object into a key.
  #
  # @since 2.2.4
  class InvalidKey < RuntimeError

    # Instantiate the exception.
    #
    # @example Instantiate the exception.
    #   BSON::Object::InvalidKey.new(object)
    #
    # @param [ Object ] object The object that was meant for the key.
    #
    # @since 2.2.4
    def initialize(object)
      super("#{object.class} instances are not allowed as keys in a BSON document.")
    end
  end

  # Enrich the core Object class with this module.
  #
  # @since 2.2.4
  ::Object.send(:include, Object)
end
