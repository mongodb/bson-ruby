# Copyright (C) 2009-2019 MongoDB Inc.
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

  # Injects behaviour for encoding and decoding time values to
  # and from raw bytes as specified by the BSON spec.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module Time

    # A time is type 0x09 in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 9.chr.force_encoding(BINARY).freeze

    # Get the time as encoded BSON.
    #
    # @example Get the time as encoded BSON.
    #   Time.new(2012, 1, 1, 0, 0, 0).to_bson
    #
    # @return [ BSON::ByteBuffer ] The buffer with the encoded object.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
      # A previous version of this method used the following implementation:
      # buffer.put_int64((to_i * 1000) + (usec / 1000))
      # Turns out, usec returned incorrect value - 999 for 1 millisecond.
      buffer.put_int64((to_f * 1000).round)
    end

    # Converts this object to a representation directly serializable to
    # Extended JSON (https://github.com/mongodb/specifications/blob/master/source/extended-json.rst).
    #
    # @option options [ true | false ] :relaxed Whether to produce relaxed
    #   extended JSON representation.
    #
    # @return [ Hash ] The extended json representation.
    def as_extended_json(**options)
      utc_time = utc
      if options[:relaxed] && (1970..9999).include?(utc_time.year)
        {'$date' => utc_time.strftime('%Y-%m-%dT%H:%M:%S.%LZ')}
      else
        {'$date' => {'$numberLong' => (utc_time.to_f * 1000).round.to_s}}
      end
    end

    module ClassMethods

      # Deserialize UTC datetime from BSON.
      #
      # @param [ ByteBuffer ] buffer The byte buffer.
      #
      # @return [ Time ] The decoded UTC datetime.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def from_bson(buffer)
        seconds, fragment = Int64.from_bson(buffer).divmod(1000)
        at(seconds, fragment * 1000).utc
      end
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, ::Time)
  end

  # Enrich the core Time class with this module.
  #
  # @since 2.0.0
  ::Time.send(:include, Time)
  ::Time.send(:extend, Time::ClassMethods)
end
