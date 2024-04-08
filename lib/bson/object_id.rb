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
  # Represents object_id data.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  class ObjectId
    include Comparable
    include JSON

    # A object_id is type 0x07 in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = ::String.new(7.chr, encoding: BINARY).freeze

    # Check equality of the object id with another object.
    #
    # @example Check if the object id is equal to the other.
    #   object_id == other
    #
    # @param [ Object ] other The object to check against.
    #
    # @return [ true, false ] If the objects are equal.
    #
    # @since 2.0.0
    def ==(other)
      return false unless other.is_a?(ObjectId)

      generate_data == other.send(:generate_data)
    end
    alias eql? ==

    # Check case equality on the object id.
    #
    # @example Check case equality.
    #   object_id === other
    #
    # @param [ Object ] other The object to check against.
    #
    # @return [ true, false ] If the objects are equal in a case.
    #
    # @since 2.0.0
    def ===(other)
      return to_str == other.to_str if other.respond_to?(:to_str)

      super
    end

    # Return a string representation of the object id for use in
    # application-level JSON serialization. This method is intentionally
    # different from #as_extended_json.
    #
    # @example Get the object id as a JSON-serializable object.
    #   object_id.as_json
    #
    # @return [ String ] The object id as a string.
    def as_json(*_)
      to_s
    end

    # Converts this object to a representation directly serializable to
    # Extended JSON (https://github.com/mongodb/specifications/blob/master/source/extended-json.rst).
    #
    # @return [ Hash ] The extended json representation.
    def as_extended_json(**_)
      { '$oid' => to_s }
    end

    # Compare this object id with another object for use in sorting.
    #
    # @example Compare the object id with the other object.
    #   object <=> other
    #
    # @param [ Object ] other The object to compare to.
    #
    # @return [ Integer ] The result of the comparison.
    #
    # @since 2.0.0
    def <=>(other)
      generate_data <=> other.to_bson.to_s
    end

    # Return the UTC time at which this ObjectId was generated. This may
    # be used instread of a created_at timestamp since this information
    # is always encoded in the object id.
    #
    # @example Get the generation time.
    #   object_id.generation_time
    #
    # @return [ Time ] The time the id was generated.
    #
    # @since 2.0.0
    def generation_time
      ::Time.at(generate_data.unpack1('N')).utc
    end
    alias to_time generation_time

    # Get the hash value for the object id.
    #
    # @example Get the hash value.
    #   object_id.hash
    #
    # @return [ Integer ] The hash value.
    #
    # @since 2.0.0
    def hash
      generate_data.hash
    end

    # Get a nice string for use with object inspection.
    #
    # @example Inspect the object id.
    #   object_id.inspect
    #
    # @return [ String ] The object id in form BSON::ObjectId('id')
    #
    # @since 2.0.0
    def inspect
      "BSON::ObjectId('#{self}')"
    end

    # Dump the raw bson when calling Marshal.dump.
    #
    # @example Dump the raw bson.
    #   Marshal.dump(object_id)
    #
    # @return [ String ] The raw bson bytes.
    #
    # @since 2.0.0
    def marshal_dump
      generate_data
    end

    # Unmarshal the data into an object id.
    #
    # @example Unmarshal the data.
    #   Marshal.load(data)
    #
    # @param [ String ] data The raw bson bytes.
    #
    # @return [ String ] The raw bson bytes.
    #
    # @since 2.0.0
    def marshal_load(data)
      @raw_data = data
    end

    # Get the object id as it's raw BSON data.
    #
    # @example Get the raw bson bytes.
    #   object_id.to_bson
    #
    # @note Since Moped's BSON and MongoDB BSON before 2.0.0 have different
    #   internal representations, we will attempt to repair the data for cases
    #   where the object was instantiated in a non-standard way. (Like a
    #   Marshal.load)
    #
    # @return [ BSON::ByteBuffer ] The buffer with the encoded object.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson(buffer = ByteBuffer.new)
      buffer.put_bytes(generate_data)
    end

    # Get the string representation of the object id.
    #
    # @example Get the object id as a string.
    #   object_id.to_s
    #
    # @return [ String ] The object id as a string.
    #
    # @since 2.0.0
    def to_s
      generate_data.to_hex_string.force_encoding(UTF8)
    end
    alias to_str to_s

    # Extract the process-specific part of the object id. This is used only
    # internally, for testing, and should not be used elsewhere.
    #
    # @return [ String ] The process portion of the id.
    #
    # @api private
    def _process_part
      to_s[8, 10]
    end

    # Extract the counter-specific part of the object id. This is used only
    # internally, for testing, and should not be used elsewhere.
    #
    # @return [ String ] The counter portion of the id.
    #
    # @api private
    def _counter_part
      to_s[18, 6]
    end

    # Extended by native code (see init.c, util.c, GeneratorExtension.java)
    #
    # @api private
    #
    # rubocop:disable Lint/EmptyClass
    class Generator
    end
    # rubocop:enable Lint/EmptyClass

    # We keep one global generator for object ids.
    @@generator = Generator.new

    # Accessor for querying the generator directly; used in testing.
    #
    # @api private
    def self._generator
      @@generator
    end

    private

    def initialize_copy(other)
      generate_data
      other.instance_variable_set(:@raw_data, @raw_data)
    end

    def generate_data
      repair if defined?(@data)

      # rubocop:disable Naming/MemoizedInstanceVariableName
      @raw_data ||= @@generator.next_object_id
      # rubocop:enable Naming/MemoizedInstanceVariableName
    end

    def repair
      @raw_data = @data.to_bson_object_id
      remove_instance_variable(:@data)
    end

    class << self
      # Deserialize the object id from raw BSON bytes.
      #
      # @example Get the object id from BSON.
      #   ObjectId.from_bson(bson)
      #
      # @param [ ByteBuffer ] buffer The byte buffer.
      # @param [ Hash ] _ An optional hash of keyword arguments (unused).
      #
      # @return [ BSON::ObjectId ] The object id.
      #
      # @since 2.0.0
      def from_bson(buffer, **_)
        from_data(buffer.get_bytes(12))
      end

      # Create a new object id from raw bytes.
      #
      # @example Create an object id from raw bytes.
      #   BSON::ObjectId.from_data(data)
      #
      # @param [ String ] data The raw bytes.
      #
      # @return [ ObjectId ] The new object id.
      #
      # @since 2.0.0
      def from_data(data)
        object_id = allocate
        object_id.instance_variable_set(:@raw_data, data)
        object_id
      end

      # Create a new object id from a string.
      #
      # @example Create an object id from the string.
      #   BSON::ObjectId.from_string(id)
      #
      # @param [ String ] string The string to create the id from.
      #
      # @raise [ BSON::Error::InvalidObjectId ] If the provided string is invalid.
      #
      # @return [ BSON::ObjectId ] The new object id.
      #
      # @since 2.0.0
      def from_string(string)
        raise Error::InvalidObjectId, "'#{string}' is an invalid ObjectId." unless legal?(string)

        from_data([ string ].pack('H*'))
      end

      # Create a new object id from a time.
      #
      # @example Create an object id from a time.
      #   BSON::ObjectId.from_time(time)
      #
      # @example Create an object id from a time, ensuring uniqueness.
      #   BSON::ObjectId.from_time(time, unique: true)
      #
      # @param [ Time ] time The time to generate from.
      # @param [ Hash ] options The options.
      #
      # @option options [ true, false ] :unique Whether the id should be
      #   unique.
      #
      # @return [ ObjectId ] The new object id.
      #
      # @since 2.0.0
      def from_time(time, options = {})
        from_data(options[:unique] ? @@generator.next_object_id(time.to_i) : [ time.to_i ].pack('Nx8'))
      end

      # Determine if the provided string is a legal object id.
      #
      # @example Is the string a legal object id?
      #   BSON::ObjectId.legal?(string)
      #
      # @param [ String ] string The string to check.
      #
      # @return [ true, false ] If the string is legal.
      #
      # @since 2.0.0
      def legal?(string)
        (string.to_s =~ /\A[0-9a-f]{24}\z/i) ? true : false
      end

      # Executes the provided block only if the size of the provided object is
      # 12. Used in legacy id repairs.
      #
      # @example Execute in a repairing block.
      #   BSON::ObjectId.repair("test") { obj }
      #
      # @param [ String, Array ] object The object to repair.
      #
      # @raise [ BSON::Error::InvalidObjectId ] If the array is not 12 elements.
      #
      # @return [ String ] The result of the block.
      #
      # @since 2.0.0
      def repair(object)
        raise Error::InvalidObjectId, "#{object.inspect} is not a valid object id." if object.size != 12

        block_given? ? yield(object) : object
      end

      # The largest numeric value that can be converted to an integer by MRI's
      # NUM2UINT. Further, the spec dictates that the time component of an
      # ObjectID must be no more than 4 bytes long, so the spec itself is
      # constrained in this regard.
      MAX_INTEGER = 2 ** 32

      # Returns an integer timestamp (seconds since the Epoch). Primarily used
      # by the generator to produce object ids.
      #
      # @note This value is guaranteed to be no more than 4 bytes in length. A
      #   time value far enough in the future to require a larger integer than
      #   4 bytes will be truncated to 4 bytes.
      #
      # @return [ Integer ] the number of seconds since the Epoch.
      def timestamp
        ::Time.now.to_i % MAX_INTEGER
      end
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, self)
  end
end
