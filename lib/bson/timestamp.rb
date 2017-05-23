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

  # Represents a timestamp type, which is predominately used for sharding.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  class Timestamp
    include JSON

    # A timestamp is type 0x11 in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 17.chr.force_encoding(BINARY).freeze

    # Key for this type when converted to extended json.
    #
    # @since 5.1.0
    EXTENDED_JSON_KEY = '$timestamp'.freeze

    # Key for the timestamp's seconds when converted to extended json.
    #
    # @since 5.1.0
    T_EXTENDED_JSON_KEY = 't'.freeze

    # Key for the timestamp's increment when converted to extended json.
    #
    # @since 5.1.0
    I_EXTENDED_JSON_KEY = 'i'.freeze

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

    # Get the timestamp as JSON hash data.
    #
    # @example Get the timestamp as a JSON hash.
    #   timestamp.as_json
    #
    # @return [ Hash ] The timestamp as a JSON hash.
    #
    # @since 2.0.0
    def as_json(*args)
      { EXTENDED_JSON_KEY => { T_EXTENDED_JSON_KEY => seconds,
                               I_EXTENDED_JSON_KEY => increment } }
    end

    # Get the timestamp as JSON hash data, complying with the Extended JSON spec.
    #
    # @example Get the timestamp as an Extended JSON hash.
    #   timestamp.as_extended_json
    #
    # @return [ Hash ] The timestamp as an Extended JSON hash.
    #
    # @since 5.1.0
    def as_extended_json
      { EXTENDED_JSON_KEY => ((seconds << 32) | increment).to_s }
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
      buffer.put_int32(increment)
      buffer.put_int32(seconds)
    end

    class << self

      # Deserialize timestamp from BSON.
      #
      # @param [ ByteBuffer ] buffer The byte buffer.
      #
      # @return [ Timestamp ] The decoded timestamp.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def from_bson(buffer)
        increment = buffer.get_int32
        seconds = buffer.get_int32
        new(seconds, increment)
      end

      # Create a Timestamp object from JSON data.
      #
      # @example Instantiate a timestamp from JSON hash data.
      #   BSON::Timestamp.json_create(hash)
      #
      # @param [ Hash ] json The json data.
      #
      # @return [ Symbol ] The new Symbol object.
      #
      # @since 5.1.0
      def json_create(json)
        if json[EXTENDED_JSON_KEY].is_a?(Hash)
            new(json[EXTENDED_JSON_KEY][T_EXTENDED_JSON_KEY],
                json[EXTENDED_JSON_KEY][I_EXTENDED_JSON_KEY])
        else
          seconds = json[EXTENDED_JSON_KEY] >> 32
          increment = ((1 << 32) - 1) & json[EXTENDED_JSON_KEY]
          new(seconds, increment)
        end
      end
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, self)
    ExtendedJSON.register(self, EXTENDED_JSON_KEY)
  end
end
