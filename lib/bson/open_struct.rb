# frozen_string_literal: true
# Copyright (C) 2016-2020 MongoDB Inc.
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

  # Injects behaviour for encoding OpenStruct objects using hashes
  # to raw bytes as specified by the BSON spec.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 4.2.0
  module OpenStruct

    # Get the OpenStruct as encoded BSON.
    #
    # @example Get the OpenStruct object as encoded BSON.
    #   OpenStruct.new({ "field" => "value" }).to_bson
    #
    # @return [ BSON::ByteBuffer ] The buffer with the encoded object.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 4.2.0
    def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
      if Environment.ruby_1_9?
        marshal_dump.dup
      else
        to_h
      end.to_bson(buffer, validating_keys)
    end

    # The BSON type for OpenStruct objects is the Hash type of 0x03.
    #
    # @example Get the bson type.
    #   struct.bson_type
    #
    # @return [ String ] The character 0x03.
    #
    # @since 4.2.0
    def bson_type
      ::Hash::BSON_TYPE
    end
  end

  ::OpenStruct.send(:include, OpenStruct) if defined?(::OpenStruct)
end
