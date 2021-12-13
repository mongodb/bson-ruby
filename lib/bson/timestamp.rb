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

  # Represents a timestamp type, which is predominately used for sharding.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  class Timestamp
    include JSON
    include Comparable

    # A timestamp is type 0x11 in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = ::String.new(17.chr, encoding: BINARY).freeze

    # Error message if an object other than a Timestamp is compared with this object.
    #
    # @since 4.3.0
    COMPARISON_ERROR_MESSAGE = 'comparison of %s with Timestamp failed'

    # @!attribute seconds
    #   @return [ Integer ] The number of seconds.
    #   @since 2.0.0
    #
    # @!attribute increment
    #   @return [ Integer ] The incrementing value.
    #   @since 2.0.0
    #
    attr_reader :seconds, :increment

    # Determine if this timestamp is equal to another object.
    #
    # @example Check the timestamp equality.
    #   timestamp == other
    #
    # @param [ Object ] other The object to compare against.
    #
    # @return [ true, false ] If the objects are equal.
    #
    # @since 2.0.0
    def ==(other)
      return false unless other.is_a?(Timestamp)
      seconds == other.seconds && increment == other.increment
    end

    # Determine if this timestamp is greater or less than another object.
    #
    # @example Compare the timestamp.
    #   timestamp < other
    #
    # @param [ Object ] other The object to compare against.
    #
    # @return [ true, false ] The result of the comparison.
    #
    # @since 4.3.0
    def <=>(other)
      raise ArgumentError.new(COMPARISON_ERROR_MESSAGE % other.class) unless other.is_a?(Timestamp)
      return 0 if self == other
      a = [ seconds, increment ]
      b = [ other.seconds, other.increment ]
      [ a, b ].sort[0] == a ? -1 : 1
    end

    # Get the timestamp as JSON hash data.
    #
    # @example Get the timestamp as a JSON hash.
    #   timestamp.as_json
    #
    # @return [ Hash ] The timestamp as a JSON hash.
    #
    # @since 2.0.0
    # @deprecated Use as_extended_json instead.
    def as_json(*args)
      as_extended_json
    end

    # Converts this object to a representation directly serializable to
    # Extended JSON (https://github.com/mongodb/specifications/blob/master/source/extended-json.rst).
    #
    # @option opts [ nil | :relaxed | :legacy ] :mode Serialization mode
    #   (default is canonical extended JSON)
    #
    # @return [ Hash ] The extended json representation.
    def as_extended_json(**options)
      { "$timestamp" => { "t" => seconds, "i" => increment } }
    end

    # Instantiate the new timestamp.
    #
    # @example Instantiate the timestamp.
    #   BSON::Timestamp.new(5, 30)
    #
    # @param [ Integer ] seconds The number of seconds.
    # @param [ Integer ] increment The increment value.
    #
    # @since 2.0.0
    def initialize(seconds, increment)
      @seconds, @increment = seconds, increment
    end

    # Get the timestamp as its encoded raw BSON bytes.
    #
    # @example Get the timestamp as BSON.
    #   timestamp.to_bson
    #
    # @return [ BSON::ByteBuffer ] The buffer with the encoded object.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
      buffer.put_uint32(increment)
      buffer.put_uint32(seconds)
    end

    # Deserialize timestamp from BSON.
    #
    # @param [ ByteBuffer ] buffer The byte buffer.
    #
    # @option options [ nil | :bson ] :mode Decoding mode to use.
    #
    # @return [ Timestamp ] The decoded timestamp.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def self.from_bson(buffer, **options)
      increment = buffer.get_uint32
      seconds = buffer.get_uint32
      new(seconds, increment)
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, self)
  end
end
