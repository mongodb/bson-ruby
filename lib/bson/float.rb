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

  # Injects behaviour for encoding and decoding floating point values
  # to and from # raw bytes as specified by the BSON spec.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module Float

    # A floating point is type 0x01 in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 1.chr.force_encoding(BINARY).freeze

    # The pack directive is for 8 byte floating points.
    #
    # @since 2.0.0
    PACK = "E".freeze

    # Get the floating point as encoded BSON.
    #
    # @example Get the floating point as encoded BSON.
    #   1.221311.to_bson
    #
    # @return [ String ] The encoded string.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson(encoded = ''.force_encoding(BINARY))
      encoded << [ self ].pack(PACK)
    end

    module ClassMethods

      # Deserialize an instance of a Float from a BSON double.
      #
      # @param [ BSON ] bson The encoded double.
      #
      # @return [ Float ] The decoded Float.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def from_bson(bson)
        from_bson_double(bson.read(8))
      end

      private

      def from_bson_double(double)
        double.unpack(PACK).first
      end
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, ::Float)
  end

  # Enrich the core Float class with this module.
  #
  # @since 2.0.0
  ::Float.send(:include, Float)
  ::Float.send(:extend, Float::ClassMethods)
end
