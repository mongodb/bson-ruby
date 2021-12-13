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

  # Represents a boolean type, which compares less than any other value in the
  # specification.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  class Boolean

    # A boolean is type 0x08 in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = ::String.new(8.chr, encoding: BINARY).freeze

    # Deserialize a boolean from BSON.
    #
    # @param [ ByteBuffer ] buffer The byte buffer.
    #
    # @option options [ nil | :bson ] :mode Decoding mode to use.
    #
    # @return [ TrueClass, FalseClass ] The decoded boolean.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def self.from_bson(buffer, **options)
      case v = buffer.get_byte
      when TrueClass::TRUE_BYTE
        true
      when FalseClass::FALSE_BYTE
        false
      else
        raise Error::BSONDecodeError, "Invalid boolean byte value: #{v}"
      end
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, self)
  end
end
