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

require 'date'

module BSON

  # Julian day of Date 1970-01-01 - UNIX timestamp reference.
  #
  # @api private
  DATE_REFERENCE = ::Date.new(1970, 1, 1).jd

  # Number of miliseconds in a day.
  #
  # @api private
  MILLISECONDS_IN_DAY = 60 * 60 * 24 * 1_000

  # Injects behaviour for encoding date values to raw bytes as specified by
  # the BSON spec for time.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.1.0
  module Date

    # Get the date as encoded BSON.
    #
    # @example Get the date as encoded BSON.
    #   Date.new(2012, 1, 1).to_bson
    #
    # @return [ BSON::ByteBuffer ] The buffer with the encoded object.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.1.0
    def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
      buffer.put_int64((jd - DATE_REFERENCE) * MILLISECONDS_IN_DAY)
    end

    # Get the BSON type for the date.
    #
    # As the date is converted to a time, this returns the BSON type for time.
    def bson_type
      ::Time::BSON_TYPE
    end
  end

  # Enrich the core Date class with this module.
  #
  # @since 2.1.0
  ::Date.send(:include, Date)
end
