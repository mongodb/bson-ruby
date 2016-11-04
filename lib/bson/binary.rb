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

require 'base64'

module BSON

  # Represents binary data.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  class Binary
    include JSON

    # A binary is type 0x05 in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 5.chr.force_encoding(BINARY).freeze

    # The mappings of subtypes to their single byte identifiers.
    #
    # @since 2.0.0
    SUBTYPES = {
      :generic => 0.chr,
      :function => 1.chr,
      :old =>  2.chr,
      :uuid_old => 3.chr,
      :uuid => 4.chr,
      :md5 => 5.chr,
      :user => 128.chr
    }.freeze

    # The mappings of single byte subtypes to their symbol counterparts.
    #
    # @since 2.0.0
    TYPES = SUBTYPES.invert.freeze

    # @!attribute data
    #   @return [ Object ] The raw binary data.
    #   @since 2.0.0
    # @!attribute type
    #   @return [ Symbol ] The binary type.
    #   @since 2.0.0
    attr_reader :data, :type

    # Determine if this binary object is equal to another object.
    #
    # @example Check the binary equality.
    #   binary == other
    #
    # @param [ Object ] other The object to compare against.
    #
    # @return [ true, false ] If the objects are equal.
    #
    # @since 2.0.0
    def ==(other)
      return false unless other.is_a?(Binary)
      type == other.type && data == other.data
    end
    alias eql? ==

    # Generates a Fixnum hash value for this object.
    #
    # Allows using Binary as hash keys.
    #
    # @return [ Fixnum ]
    #
    # @since 2.3.1
    def hash
      data.hash + type.hash
    end

    # Get the binary as JSON hash data.
    #
    # @example Get the binary as a JSON hash.
    #   binary.as_json
    #
    # @return [ Hash ] The binary as a JSON hash.
    #
    # @since 2.0.0
    def as_json(*args)
      { "$binary" => Base64.encode64(data), "$type" => type }
    end

    # Instantiate the new binary object.
    #
    # @example Instantiate a binary.
    #   BSON::Binary.new(data, :md5)
    #
    # @param [ Object ] data The raw binary data.
    # @param [ Symbol ] type The binary type.
    #
    # @since 2.0.0
    def initialize(data = "", type = :generic)
      validate_type!(type)
      @data = data
      @type = type
    end

    # Get a nice string for use with object inspection.
    #
    # @example Inspect the binary.
    #   object_id.inspect
    #
    # @return [ String ] The binary in form BSON::Binary:object_id
    #
    # @since 2.3.0
    def inspect
      "<BSON::Binary:0x#{object_id} type=#{type} data=0x#{data[0, 8].unpack('H*').first}...>"
    end

    # Encode the binary type
    #
    # @example Encode the binary.
    #   binary.to_bson
    #
    # @return [ BSON::ByteBuffer ] The buffer with the encoded object.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
      position = buffer.length
      buffer.put_int32(0)
      buffer.put_byte(SUBTYPES[type])
      buffer.put_int32(data.bytesize) if type == :old
      buffer.put_bytes(data.force_encoding(BINARY))
      buffer.replace_int32(position, buffer.length - position - 5)
    end

    # Deserialize the binary data from BSON.
    #
    # @param [ ByteBuffer ] buffer The byte buffer.
    #
    # @return [ Binary ] The decoded binary data.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def self.from_bson(buffer)
      length = buffer.get_int32
      type = TYPES[buffer.get_byte]
      length = buffer.get_int32 if type == :old
      data = buffer.get_bytes(length)
      new(data, type)
    end

    # Raised when providing an invalid type to the Binary.
    #
    # @since 2.0.0
    class InvalidType < RuntimeError

      # @!attribute type
      #   @return [ Object ] The invalid type.
      #   @since 2.0.0
      attr_reader :type

      # Instantiate the new error.
      #
      # @example Instantiate the error.
      #   InvalidType.new(:error)
      #
      # @param [ Object ] type The invalid type.
      #
      # @since 2.0.0
      def initialize(type)
        @type = type
      end

      # Get the custom error message for the exception.
      #
      # @example Get the message.
      #   error.message
      #
      # @return [ String ] The error message.
      #
      # @since 2.0.0
      def message
        "#{type.inspect} is not a valid binary type. " +
          "Please use one of #{SUBTYPES.keys.map(&:inspect).join(", ")}."
      end
    end

    private

    # Validate the provided type is a valid type.
    #
    # @api private
    #
    # @example Validate the type.
    #   binary.validate_type!(:user)
    #
    # @param [ Object ] type The provided type.
    #
    # @raise [ InvalidType ] The the type is invalid.
    #
    # @since 2.0.0
    def validate_type!(type)
      raise InvalidType.new(type) unless SUBTYPES.has_key?(type)
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, self)
  end
end
