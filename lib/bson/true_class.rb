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

  # Injects behaviour for encoding and decoding true values to and from
  # raw bytes as specified by the BSON spec.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module TrueClass

    # A true value in the BSON spec is 0x01.
    #
    # @since 2.0.0
    TRUE_BYTE = ::String.new(1.chr, encoding: BINARY).freeze

    # The BSON type for true values is the general boolean type of 0x08.
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

    # Get the true boolean as encoded BSON.
    #
    # @example Get the true boolean as encoded BSON.
    #   true.to_bson
    #
    # @return [ BSON::ByteBuffer ] The buffer with the encoded object.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
      buffer.put_byte(TRUE_BYTE)
    end
  end

  # Enrich the core TrueClass class with this module.
  #
  # @since 2.0.0
  ::TrueClass.send(:include, TrueClass)
end
