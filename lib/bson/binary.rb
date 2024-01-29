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
      generic: 0.chr,
      function: 1.chr,
      old: 2.chr,
      uuid_old: 3.chr,
      uuid: 4.chr,
      md5: 5.chr,
      ciphertext: 6.chr,
      column: 7.chr,
      sensitive: 8.chr,
      user: 128.chr,
    }.freeze

    # The starting point of the user-defined subtype range.
    USER_SUBTYPE = 0x80

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
    attr_reader :type

    # @return [ String ] The raw type value, as an encoded integer.
    attr_reader :raw_type

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
      [ data, type ].hash
    end

    # Return a representation of the object for use in
    # application-level JSON serialization. Since BSON::Binary
    # is used exclusively in BSON-related contexts, this
    # method returns the canonical Extended JSON representation.
    #
    # @return [ Hash ] The extended json representation.
    def as_json(*_args)
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
      subtype = @raw_type.each_byte.map { |c| c.to_s(16) }.join
      subtype = "0#{subtype}" if subtype.length == 1

      value = Base64.encode64(data).strip

      if options[:mode] == :legacy
        { '$binary' => value, '$type' => subtype }
      else
        { '$binary' => { 'base64' => value, 'subType' => subtype } }
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
    def initialize(data = '', type = :generic)
      initialize_instance(data, type)
    end

    # For legacy deserialization support where BSON::Binary objects are
    # expected to have a specific internal representation (with only
    # @type and @data instance variables).
    #
    # @api private
    def init_with(coder)
      initialize_instance(coder['data'], coder['type'])
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
        raise ArgumentError,
              "Representation must be given as a symbol: #{representation.inspect}"
      end

      case type
      when :uuid
        from_uuid_to_uuid(representation || :standard)
      when :uuid_old
        from_uuid_old_to_uuid(representation)
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
    def to_bson(buffer = ByteBuffer.new)
      position = buffer.length
      buffer.put_int32(0)
      buffer.put_byte(@raw_type)
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
    def self.from_bson(buffer, **_options)
      length = buffer.get_int32
      type_byte = buffer.get_byte

      if type_byte.bytes.first < USER_SUBTYPE
        type = TYPES[type_byte]

        if type.nil?
          raise Error::UnsupportedBinarySubtype,
                "BSON data contains unsupported binary subtype #{'0x%02x' % type_byte.ord}"
        end
      else
        type = type_byte
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
      raise ArgumentError, "Representation must be given as a symbol: #{representation}" if representation.is_a?(String)

      uuid_binary = uuid.delete('-').scan(/../).map(&:hex).map(&:chr).join
      representation ||= :standard

      handler = :"from_#{representation}_uuid"
      raise ArgumentError, "Invalid representation: #{representation}" unless respond_to?(handler)

      send(handler, uuid_binary)
    end

    # Constructs a new binary object from a standard-format binary UUID
    # representation.
    #
    # @param [ String ] uuid_binary the UUID data
    #
    # @return [ BSON::Binary ] the Binary object
    #
    # @api private
    def self.from_standard_uuid(uuid_binary)
      new(uuid_binary, :uuid)
    end

    # Constructs a new binary object from a csharp legacy-format binary UUID
    # representation.
    #
    # @param [ String ] uuid_binary the UUID data
    #
    # @return [ BSON::Binary ] the Binary object
    #
    # @api private
    def self.from_csharp_legacy_uuid(uuid_binary)
      uuid_binary.sub!(/\A(.)(.)(.)(.)(.)(.)(.)(.)(.{8})\z/, '\4\3\2\1\6\5\8\7\9')
      new(uuid_binary, :uuid_old)
    end

    # Constructs a new binary object from a java legacy-format binary UUID
    # representation.
    #
    # @param [ String ] uuid_binary the UUID data
    #
    # @return [ BSON::Binary ] the Binary object
    #
    # @api private
    def self.from_java_legacy_uuid(uuid_binary)
      uuid_binary.sub!(/\A(.)(.)(.)(.)(.)(.)(.)(.)(.)(.)(.)(.)(.)(.)(.)(.)\z/) do
        (::Regexp.last_match[1..8].reverse + ::Regexp.last_match[9..16].reverse).join
      end
      new(uuid_binary, :uuid_old)
    end

    # Constructs a new binary object from a python legacy-format binary UUID
    # representation.
    #
    # @param [ String ] uuid_binary the UUID data
    #
    # @return [ BSON::Binary ] the Binary object
    #
    # @api private
    def self.from_python_legacy_uuid(uuid_binary)
      new(uuid_binary, :uuid_old)
    end

    private

    # initializes an instance of BSON::Binary.
    #
    # @param [ String ] data the data to initialize the object with
    # @param [ Symbol ] type the type to assign the binary object
    def initialize_instance(data, type)
      @type = validate_type!(type)

      # The Binary class used to force encoding to BINARY when serializing to
      # BSON. Instead of doing that during serialization, perform this
      # operation during Binary construction to make it clear that once
      # the string is given to the Binary, the data is treated as a binary
      # string and not a text string in any encoding.
      data = data.dup.force_encoding('BINARY') unless data.encoding == Encoding.find('BINARY')

      @data = data
    end

    # Converts the Binary UUID object to a UUID of the given representation.
    # Currently, only :standard representation is supported.
    #
    # @param [ Symbol ] representation The representation to target (must be
    #   :standard)
    #
    # @return [ String ] the UUID as a string
    def from_uuid_to_uuid(representation)
      if representation != :standard
        raise ArgumentError,
              'Binary of type :uuid can only be stringified to :standard representation, ' \
              "requested: #{representation.inspect}"
      end

      data
        .chars
        .map { |n| '%02x' % n.ord }
        .join
        .sub(/\A(.{8})(.{4})(.{4})(.{4})(.{12})\z/, '\1-\2-\3-\4-\5')
    end

    # Converts the UUID-old object to a UUID of the given representation.
    #
    # @param [ Symbol ] representation The representation to target
    #
    # @return [ String ] the UUID as a string
    def from_uuid_old_to_uuid(representation)
      if representation.nil?
        raise ArgumentError, 'Representation must be specified for BSON::Binary objects of type :uuid_old'
      end

      hex = data.chars.map { |n| '%02x' % n.ord }.join
      handler = :"from_uuid_old_to_#{representation}_uuid"

      raise ArgumentError, "Invalid representation: #{representation}" unless respond_to?(handler, true)

      send(handler, hex)
        .sub(/\A(.{8})(.{4})(.{4})(.{4})(.{12})\z/, '\1-\2-\3-\4-\5')
    end

    # Tries to convert a UUID-old object to a standard representation, which is
    # not supported.
    #
    # @param [ String ] hex The hexadecimal string to convert
    #
    # @raise [ ArgumentError ] because standard representation is not supported
    def from_uuid_old_to_standard_uuid(_hex)
      raise ArgumentError, 'BSON::Binary objects of type :uuid_old cannot be stringified to :standard representation'
    end

    # Converts a UUID-old object to a csharp-legacy representation.
    #
    # @param [ String ] hex The hexadecimal string to convert
    #
    # @return [ String ] the csharp-legacy-formatted UUID
    def from_uuid_old_to_csharp_legacy_uuid(hex)
      hex.sub(/\A(..)(..)(..)(..)(..)(..)(..)(..)(.{16})\z/, '\4\3\2\1\6\5\8\7\9')
    end

    # Converts a UUID-old object to a java-legacy representation.
    #
    # @param [ String ] hex The hexadecimal string to convert
    #
    # @return [ String ] the java-legacy-formatted UUID
    def from_uuid_old_to_java_legacy_uuid(hex)
      hex.sub(/\A(..)(..)(..)(..)(..)(..)(..)(..)(..)(..)(..)(..)(..)(..)(..)(..)\z/) do
        (::Regexp.last_match[1..8].reverse + ::Regexp.last_match[9..16].reverse).join
      end
    end

    # Converts a UUID-old object to a python-legacy representation.
    #
    # @param [ String ] hex The hexadecimal string to convert
    #
    # @return [ String ] the python-legacy-formatted UUID
    def from_uuid_old_to_python_legacy_uuid(hex)
      hex
    end

    # Validate the provided type is a valid type.
    #
    # @api private
    #
    # @example Validate the type.
    #   binary.validate_type!(:user)
    #
    # @param [ Symbol | String | Integer ] type The provided type.
    #
    # @return [ Symbol ] the symbolic type corresponding to the argument.
    #
    # @raise [ BSON::Error::InvalidBinaryType ] The the type is invalid.
    #
    # @since 2.0.0
    def validate_type!(type)
      case type
      when Integer then validate_integer_type!(type)
      when String
        if type.length > 1
          validate_symbol_type!(type.to_sym)
        else
          validate_integer_type!(type.bytes.first)
        end
      when Symbol then validate_symbol_type!(type)
      else raise BSON::Error::InvalidBinaryType, type
      end
    end

    # Test that the given integer type is valid.
    #
    # @param [ Integer ] type the provided type
    #
    # @return [ Symbol ] the symbolic type corresponding to the argument.
    #
    # @raise [ BSON::Error::InvalidBinaryType] if the type is invalid.
    def validate_integer_type!(type)
      @raw_type = type.chr.force_encoding('BINARY').freeze

      if type < USER_SUBTYPE
        raise BSON::Error::InvalidBinaryType, type unless TYPES.key?(@raw_type)

        return TYPES[@raw_type]
      end

      :user
    end

    # Test that the given symbol type is valid.
    #
    # @param [ Symbol ] type the provided type
    #
    # @return [ Symbol ] the symbolic type corresponding to the argument.
    #
    # @raise [ BSON::Error::InvalidBinaryType] if the type is invalid.
    def validate_symbol_type!(type)
      raise BSON::Error::InvalidBinaryType, type unless SUBTYPES.key?(type)

      @raw_type = SUBTYPES[type]
      type
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, self)
  end
end
