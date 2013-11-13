# Copyright (C) 2009-2013 MongoDB Inc.
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

  # Represents binary data.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  class Binary
    include JSON
    include Encodable

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

    # Get the binary as JSON hash data.
    #
    # @example Get the binary as a JSON hash.
    #   binary.as_json
    #
    # @return [ Hash ] The binary as a JSON hash.
    #
    # @since 2.0.0
    def as_json(*args)
      { "$binary" => data, "$type" => type }
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

    # Encode the binary type
    #
    # @example Encode the binary.
    #   binary.to_bson
    #
    # @return [ String ] The encoded binary.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson(encoded = ''.force_encoding(BINARY))
      encode_binary_data_with_placeholder(encoded) do |encoded|
        encoded << SUBTYPES.fetch(type)
        encoded << data.bytesize.to_bson if type == :old
        encoded << data
      end
    end

    # Deserialize the binary data from BSON.
    #
    # @param [ BSON ] bson The bson representing binary data.
    #
    # @return [ Binary ] The decoded binary data.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def self.from_bson(bson)
      length = Int32.from_bson(bson)
      type = TYPES[bson.read(1)]
      length = Int32.from_bson(bson) if type == :old
      data = bson.read(length)
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
