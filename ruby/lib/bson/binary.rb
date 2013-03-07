# encoding: utf-8
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

    # Get the binary data formatted for its subtype
    #
    # If type is :old we include the size of the data
    #
    # @see http://bsonspec.org/#specification
    #
    # @since @2.0.0
    def bin_data
      if type == :old
        data.bytesize.to_bson + data
      else
        data
      end
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
    def to_bson
      bin_data.bytesize.to_bson + SUBTYPES.fetch(type) + bin_data
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
      length = bson.read(4).unpack(Int32::PACK).first
      type = SUBTYPES.invert[bson.read(1)]

      if type == :old
        length = bson.read(4).unpack(Int32::PACK).first
      end

      data = bson.read(length)
      new(data, type)
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, self)
  end
end
