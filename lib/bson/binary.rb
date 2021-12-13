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
    BSON_TYPE = ::String.new(5.chr, encoding: BINARY).freeze

    # The mappings of subtypes to their single byte identifiers.
    #
    # @note subtype 6 (ciphertext) is used for the Client-Side Encryption
    #   feature. Data represented by this subtype is often encrypted, but
    #   may also be plaintext. All instances of this subtype necessary for
    #   Client-Side Encryption will be created internally by the Ruby driver.
    #   An application should not create new BSON::Binary objects of this subtype.
    #
    # @since 2.0.0
    SUBTYPES = {
      :generic => 0.chr,
      :function => 1.chr,
      :old =>  2.chr,
      :uuid_old => 3.chr,
      :uuid => 4.chr,
      :md5 => 5.chr,
      :ciphertext => 6.chr,
      :column => 7.chr,
      :user => 128.chr,
    }.freeze

    # The mappings of single byte subtypes to their symbol counterparts.
    #
    # @since 2.0.0
    TYPES = SUBTYPES.invert.freeze

    # @return [ String ] The raw binary data.
    #
    # The string is always stored in BINARY encoding.
    #
    # @since 2.0.0
    attr_reader :data

    # @return [ Symbol ] The binary type.
    #
    # @since 2.0.0
    attr_reader :type

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
      subtype = SUBTYPES[type].each_byte.map { |c| c.to_s(16) }.join
      if subtype.length == 1
        subtype = "0#{subtype}"
      end

      value = Base64.encode64(data).strip

      if options[:mode] == :legacy
        { "$binary" => value, "$type" => subtype }
      else
        { "$binary" => {'base64' => value, "subType" => subtype }}
      end
    end

    # Instantiate the new binary object.
    #
    # This method accepts a string in any encoding; however, if a string is
    # of a non-BINARY encoding, the encoding is set to BINARY. This does not
    # change the bytes of the string but it means that applications referencing
    # the data of a Binary instance cannot assume it is in a non-binary
    # encoding, even if the string given to the constructor was in such an
    # encoding.
    #
    # @example Instantiate a binary.
    #   BSON::Binary.new(data, :md5)
    #
    # @param [ String ] data The raw binary data.
    # @param [ Symbol ] type The binary type.
    #
    # @since 2.0.0
    def initialize(data = "", type = :generic)
      validate_type!(type)

      # The Binary class used to force encoding to BINARY when serializing to
      # BSON. Instead of doing that during serialization, perform this
      # operation during Binary construction to make it clear that once
      # the string is given to the Binary, the data is treated as a binary
      # string and not a text string in any encoding.
      unless data.encoding == Encoding.find('BINARY')
        data = data.dup.force_encoding('BINARY')
      end

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
      "<BSON::Binary:0x#{object_id} type=#{type} data=0x#{data[0, 8].unpack1('H*')}...>"
    end

    # Returns a string representation of the UUID stored in this Binary.
    #
    # If the Binary is of subtype 4 (:uuid), this method returns the UUID
    # in RFC 4122 format. If the representation parameter is provided, it
    # must be the value :standard as a symbol or a string.
    #
    # If the Binary is of subtype 3 (:uuid_old), this method requires that
    # the representation parameter is provided and is one of :csharp_legacy,
    # :java_legacy or :python_legacy or the equivalent strings. In this case
    # the method assumes the Binary stores the UUID in the specified format,
    # transforms the stored bytes to the standard RFC 4122 representation
    # and returns the UUID in RFC 4122 format.
    #
    # If the Binary is of another subtype, this method raises TypeError.
    #
    # @param [ Symbol ] representation How to interpret the UUID.
    #
    # @return [ String ] The string representation of the UUID.
    #
    # @raise [ TypeError ] If the subtype of Binary is not :uuid nor :uuid_old.
    # @raise [ ArgumentError ] If the representation other than :standard
    #   is requested for Binary subtype 4 (:uuid), if :standard representation
    #   is requested for Binary subtype 3 (:uuid_old), or if an invalid
    #   representation is requested.
    #
    # @api experimental
    def to_uuid(representation = nil)
      if representation.is_a?(String)
        raise ArgumentError, "Representation must be given as a symbol: #{representation}"
      end
      case type
      when :uuid
        if representation && representation != :standard
          raise ArgumentError, "Binary of type :uuid can only be stringified to :standard representation, requested: #{representation.inspect}"
        end

        data.split('').map { |n| '%02x' % n.ord }.join.sub(/\A(.{8})(.{4})(.{4})(.{4})(.{12})\z/, '\1-\2-\3-\4-\5')
      when :uuid_old
        if representation.nil?
          raise ArgumentError, 'Representation must be specified for BSON::Binary objects of type :uuid_old'
        end

        hex = data.split('').map { |n| '%02x' % n.ord }.join

        case representation
        when :standard
          raise ArgumentError, 'BSON::Binary objects of type :uuid_old cannot be stringified to :standard representation'
        when :csharp_legacy
          hex.sub(/\A(..)(..)(..)(..)(..)(..)(..)(..)(.{16})\z/, '\4\3\2\1\6\5\8\7\9')
        when :java_legacy
          hex.sub(/\A(..)(..)(..)(..)(..)(..)(..)(..)(..)(..)(..)(..)(..)(..)(..)(..)\z/) do |m|
            "#{$8}#{$7}#{$6}#{$5}#{$4}#{$3}#{$2}#{$1}" +
            "#{$16}#{$15}#{$14}#{$13}#{$12}#{$11}#{$10}#{$9}"
          end
        when :python_legacy
          hex
        else
          raise ArgumentError, "Invalid representation: #{representation}"
        end.sub(/\A(.{8})(.{4})(.{4})(.{4})(.{12})\z/, '\1-\2-\3-\4-\5')
      else
        raise TypeError, "The type of Binary must be :uuid or :uuid_old, this object is: #{type.inspect}"
      end
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
      buffer.put_bytes(data)
      buffer.replace_int32(position, buffer.length - position - 5)
    end

    # Deserialize the binary data from BSON.
    #
    # @param [ ByteBuffer ] buffer The byte buffer.
    #
    # @option options [ nil | :bson ] :mode Decoding mode to use.
    #
    # @return [ Binary ] The decoded binary data.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def self.from_bson(buffer, **options)
      length = buffer.get_int32
      type_byte = buffer.get_byte
      type = TYPES[type_byte]
      if type.nil?
        raise Error::UnsupportedBinarySubtype,
          "BSON data contains unsupported binary subtype #{'0x%02x' % type_byte.ord}"
      end

      length = buffer.get_int32 if type == :old
      data = buffer.get_bytes(length)
      new(data, type)
    end

    # Creates a BSON::Binary from a string representation of a UUID.
    #
    # The UUID may be given in either 00112233-4455-6677-8899-aabbccddeeff or
    # 00112233445566778899AABBCCDDEEFF format - specifically, any dashes in
    # the UUID are removed and both upper and lower case letters are acceptable.
    #
    # The input UUID string is always interpreted to be in the RFC 4122 format.
    #
    # If representation is not provided, this method creates a BSON::Binary
    # of subtype 4 (:uuid). If representation is provided, it must be one of
    # :standard, :csharp_legacy, :java_legacy or :python_legacy. If
    # representation is :standard, this method creates a subtype 4 (:uuid)
    # binary which is the same behavior as if representation was not provided.
    # For other representations, this method creates a Binary of subtype 3
    # (:uuid_old) with the UUID converted to the appropriate legacy MongoDB
    # UUID storage format.
    #
    # @param [ String ] uuid The string representation of the UUID.
    # @param [ Symbol ] representation How to interpret the UUID.
    #
    # @return [ Binary ] The binary.
    #
    # @raise [ ArgumentError ] If invalid representation is requested.
    #
    # @api experimental
    def self.from_uuid(uuid, representation = nil)
      if representation.is_a?(String)
        raise ArgumentError, "Representation must be given as a symbol: #{representation}"
      end
      uuid_binary = uuid.gsub('-', '').scan(/../).map(&:hex).map(&:chr).join
      case representation && representation
      when nil, :standard
        new(uuid_binary, :uuid)
      when :csharp_legacy
        uuid_binary.sub!(/\A(.)(.)(.)(.)(.)(.)(.)(.)(.{8})\z/, '\4\3\2\1\6\5\8\7\9')
        new(uuid_binary, :uuid_old)
      when :java_legacy
        uuid_binary.sub!(/\A(.)(.)(.)(.)(.)(.)(.)(.)(.)(.)(.)(.)(.)(.)(.)(.)\z/) do |m|
          "#{$8}#{$7}#{$6}#{$5}#{$4}#{$3}#{$2}#{$1}" +
          "#{$16}#{$15}#{$14}#{$13}#{$12}#{$11}#{$10}#{$9}"
        end
        new(uuid_binary, :uuid_old)
      when :python_legacy
        new(uuid_binary, :uuid_old)
      else
        raise ArgumentError, "Invalid representation: #{representation}"
      end
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
