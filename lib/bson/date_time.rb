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

require "time"

module BSON

  # Injects behaviour for encoding date time values to raw bytes as specified by
  # the BSON spec for time.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.1.0
  module DateTime

    # Get the date time as encoded BSON.
    #
    # @example Get the date time as encoded BSON.
    #   DateTime.new(2012, 1, 1, 0, 0, 0).to_bson
    #
    # @return [ BSON::ByteBuffer ] The buffer with the encoded object.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.1.0
    def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
      gregorian.to_time.to_bson(buffer)
    end
  end

  # Enrich the core DateTime class with this module.
  #
  # @since 2.1.0
  ::DateTime.send(:include, DateTime)
end
