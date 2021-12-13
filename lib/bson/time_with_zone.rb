# frozen_string_literal: true
# Copyright (C) 2018-2020 MongoDB Inc.
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

require "active_support/time_with_zone"

module BSON

  # Injects behaviour for encoding ActiveSupport::TimeWithZone values to
  # raw bytes as specified by the BSON spec for time.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 4.4.0
  module TimeWithZone

    # Get the ActiveSupport::TimeWithZone as encoded BSON.
    #
    # @example Get the ActiveSupport::TimeWithZone as encoded BSON.
    #   Time.utc(2012, 12, 12, 0, 0, 0).in_time_zone("Pacific Time (US & Canada)").to_bson
    #
    # @return [ BSON::ByteBuffer ] The buffer with the encoded object.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 4.4.0
    def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
      buffer.put_int64((to_i * 1000) + (usec / 1000))
    end

    # Get the BSON type for the ActiveSupport::TimeWithZone.
    #
    # As the ActiveSupport::TimeWithZone is converted to a time, this returns
    # the BSON type for time.
    def bson_type
      ::Time::BSON_TYPE
    end
  end

  # Enrich the ActiveSupport::TimeWithZone class with this module.
  #
  # @since 4.4.0
  ActiveSupport::TimeWithZone.send(:include, TimeWithZone)
end
