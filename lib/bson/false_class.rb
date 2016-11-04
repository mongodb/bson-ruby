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

  # Injects behaviour for encoding and decoding false values to and from
  # raw bytes as specified by the BSON spec.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module FalseClass

    # A false value in the BSON spec is 0x00.
    #
    # @since 2.0.0
    FALSE_BYTE = 0.chr.force_encoding(BINARY).freeze

    # The BSON type for false values is the general boolean type of 0x08.
    #
    # @example Get the bson type.
    #   false.bson_type
    #
    # @return [ String ] The character 0x08.
    #
    # @since 2.0.0
    def bson_type
      Boolean::BSON_TYPE
    end

    # Get the false boolean as encoded BSON.
    #
    # @example Get the false boolean as encoded BSON.
    #   false.to_bson
    #
    # @return [ BSON::ByteBuffer ] The buffer with the encoded object.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
      buffer.put_byte(FALSE_BYTE)
    end
  end

  # Enrich the core FalseClass class with this module.
  #
  # @since 2.0.0
  ::FalseClass.send(:include, FalseClass)
end
