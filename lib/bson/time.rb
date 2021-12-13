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

  # Injects behaviour for encoding and decoding time values to
  # and from raw bytes as specified by the BSON spec.
  #
  # @note
  #   Ruby time can have nanosecond precision:
  #   +Time.utc(2020, 1, 1, 0, 0, 0, 999_999_999/1000r)+
  #   +Time#usec+ returns the number of microseconds in the time, and
  #   if the time has nanosecond precision the sub-microsecond part is
  #   truncated (the value is floored to the nearest millisecond).
  #   MongoDB only supports millisecond precision; we truncate the
  #   sub-millisecond part of microseconds (floor to the nearest millisecond).
  #   Note that if a time is constructed from a floating point value,
  #   the microsecond value may round to the starting floating point value
  #   but due to flooring, the time after serialization may end up to
  #   be different than the starting floating point value.
  #   It is recommended that time calculations use integer math only.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module Time

    # A time is type 0x09 in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = ::String.new(9.chr, encoding: BINARY).freeze

    # Get the time as encoded BSON.
    #
    # @note The time is floored to the nearest millisecond.
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
      value = _bson_to_i * 1000 + usec.divmod(1000).first
      buffer.put_int64(value)
    end

    # Converts this object to a representation directly serializable to
    # Extended JSON (https://github.com/mongodb/specifications/blob/master/source/extended-json.rst).
    #
    # @note The time is floored to the nearest millisecond.
    #
    # @option opts [ nil | :relaxed | :legacy ] :mode Serialization mode
    #   (default is canonical extended JSON)
    #
    # @return [ Hash ] The extended json representation.
    def as_extended_json(**options)
      utc_time = utc
      if options[:mode] == :relaxed && (1970..9999).include?(utc_time.year)
        if utc_time.usec != 0
          if utc_time.respond_to?(:floor)
            # Ruby 2.7+
            utc_time = utc_time.floor(3)
          else
            utc_time -= utc_time.usec.divmod(1000).last.to_r / 1000000
          end
          {'$date' => utc_time.strftime('%Y-%m-%dT%H:%M:%S.%LZ')}
        else
          {'$date' => utc_time.strftime('%Y-%m-%dT%H:%M:%SZ')}
        end
      else
        sec = utc_time._bson_to_i
        msec = utc_time.usec.divmod(1000).first
        {'$date' => {'$numberLong' => (sec * 1000 + msec).to_s}}
      end
    end

    def _bson_to_i
      # Workaround for JRuby's #to_i rounding negative timestamps up
      # rather than down (https://github.com/jruby/jruby/issues/6104)
      if BSON::Environment.jruby?
        (self - usec.to_r/1000000).to_i
      else
        to_i
      end
    end

    module ClassMethods

      # Deserialize UTC datetime from BSON.
      #
      # @param [ ByteBuffer ] buffer The byte buffer.
      #
      # @option options [ nil | :bson ] :mode Decoding mode to use.
      #
      # @return [ Time ] The decoded UTC datetime.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def from_bson(buffer, **options)
        seconds, fragment = Int64.from_bson(buffer, mode: nil).divmod(1000)
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
