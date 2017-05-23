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

require 'date'

module BSON

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
      ::Time.utc(year, month, day).to_bson(buffer)
    end

    # Get the BSON type for the date.
    #
    # As the date is converted to a time, this returns the BSON type for time.
    def bson_type
      ::Time::BSON_TYPE
    end

    # Get the object as JSON hash data, complying with the Extended JSON spec.
    #
    # @example Get the object as an Extended JSON hash.
    #   date.as_extended_json
    #
    # @return [ Hash ] The date as an Extended JSON hash.
    #
    # @since 5.1.0
    def as_extended_json
      ::Time.utc(year, month, day).as_extended_json
    end

    # Get the extended JSON representation of this object.
    #
    # @example Convert the object to extended JSON
    #   object.to_extended_json
    #
    # @return [ String ] The object as extended JSON.
    #
    # @since 5.1.0
    def to_extended_json(*args)
      as_extended_json.to_json(*args)
    end
  end

  # Enrich the core Date class with this module.
  #
  # @since 2.1.0
  ::Date.send(:include, Date)
end
