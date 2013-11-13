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

  # Injects behaviour for encoding and decoding nil values to and from
  # raw bytes as specified by the BSON spec.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module NilClass

    # A nil is type 0x0A in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 10.chr.force_encoding(BINARY).freeze

    # Get the nil as encoded BSON.
    #
    # @example Get the nil as encoded BSON.
    #   nil.to_bson
    #
    # @return [ String ] An empty string.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson(encoded = ''.force_encoding(BINARY))
      encoded
    end

    module ClassMethods
      # Deserialize NilClass from BSON.
      #
      # @param [ BSON ] bson The encoded Null value.
      #
      # @return [ nil ] The decoded nil value.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def from_bson(bson)
        nil
      end
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, ::NilClass)
  end

  # Enrich the core NilClass class with this module.
  #
  # @since 2.0.0
  ::NilClass.send(:include, NilClass)
  ::NilClass.send(:extend, NilClass::ClassMethods)
end
