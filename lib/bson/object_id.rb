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

require "digest/md5"
require "socket"
require "thread"

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
    alias :eql? :==

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
      return to_str === other.to_str if other.respond_to?(:to_str)
      super
    end

    # Return the object id as a JSON hash representation.
    #
    # @example Get the object id as JSON.
    #   object_id.as_json
    #
    # @return [ Hash ] The object id as a JSON hash.
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
      { "$oid" => to_s }
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
      ::Time.at(generate_data.unpack1("N")).utc
    end
    alias :to_time :generation_time

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
      "BSON::ObjectId('#{to_s}')"
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
    def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
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
    alias :to_str :to_s

    # Raised when trying to create an object id with invalid data.
    #
    # @since 2.0.0
    class Invalid < RuntimeError; end

    private

    def initialize_copy(other)
      generate_data
      other.instance_variable_set(:@raw_data, @raw_data)
    end

    def generate_data
      repair if defined?(@data)
      @raw_data ||= @@generator.next_object_id
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
      #
      # @option options [ nil | :bson ] :mode Decoding mode to use.
      #
      # @return [ BSON::ObjectId ] The object id.
      #
      # @since 2.0.0
      def from_bson(buffer, **options)
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
      # @raise [ BSON::ObjectId::Invalid ] If the provided string is invalid.
      #
      # @return [ BSON::ObjectId ] The new object id.
      #
      # @since 2.0.0
      def from_string(string)
        unless legal?(string)
          raise Invalid.new("'#{string}' is an invalid ObjectId.")
        end
        from_data([ string ].pack("H*"))
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
        from_data(options[:unique] ? @@generator.next_object_id(time.to_i) : [ time.to_i ].pack("Nx8"))
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
        string.to_s =~ /\A[0-9a-f]{24}\z/i ? true : false
      end

      # Executes the provided block only if the size of the provided object is
      # 12. Used in legacy id repairs.
      #
      # @example Execute in a repairing block.
      #   BSON::ObjectId.repair("test") { obj }
      #
      # @param [ String, Array ] object The object to repair.
      #
      # @raise [ Invalid ] If the array is not 12 elements.
      #
      # @return [ String ] The result of the block.
      #
      # @since 2.0.0
      def repair(object)
        if object.size == 12
          block_given? ? yield(object) : object
        else
          raise Invalid.new("#{object.inspect} is not a valid object id.")
        end
      end
    end

    # Inner class that encapsulates the behaviour of actually generating each
    # part of the ObjectId.
    #
    # @api private
    #
    # @since 2.0.0
    class Generator

      # @!attribute machine_id
      #   @return [ String ] The unique machine id.
      #   @since 2.0.0
      attr_reader :machine_id

      # Instantiate the new object id generator. Will set the machine id once
      # on the initial instantiation.
      #
      # @example Instantiate the generator.
      #   BSON::ObjectId::Generator.new
      #
      # @since 2.0.0
      def initialize
        @counter = rand(0x1000000)
        @machine_id = Digest::MD5.digest(Socket.gethostname).unpack1("N")
        @mutex = Mutex.new
      end

      # Return object id data based on the current time, incrementing the
      # object id counter. Will use the provided time if not nil.
      #
      # @example Get the next object id data.
      #   generator.next_object_id
      #
      # @param [ Time ] time The optional time to generate with.
      #
      # @return [ String ] The raw object id bytes.
      #
      # @since 2.0.0
      def next_object_id(time = nil)
        @mutex.lock
        begin
          count = @counter = (@counter + 1) % 0xFFFFFF
        ensure
          @mutex.unlock rescue nil
        end
        generate(time || ::Time.new.to_i, count)
      end

      # Generate object id data for a given time using the provided counter.
      #
      # @example Generate the object id bytes.
      #   generator.generate(time)
      #
      # @param [ Integer ] time The time since epoch in seconds.
      # @param [ Integer ] counter The optional counter.
      #
      # @return [ String ] The raw object id bytes.
      #
      # @since 2.0.0
      def generate(time, counter = 0)
        [ time, machine_id, process_id, counter << 8 ].pack("N NX lXX NX")
      end

      private

      if Environment.jruby?
        def process_id
          "#{Process.pid}#{Thread.current.object_id}".hash % 0xFFFF
        end
      else
        def process_id
          Process.pid % 0xFFFF
        end
      end
    end

    # We keep one global generator for object ids.
    #
    # @since 2.0.0
    @@generator = Generator.new

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, self)
  end
end
