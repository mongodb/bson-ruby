module BSON
  class Binary
    include Element

    BSON_TYPE = "\x05"

    BSON_SUB_TYPES = {
      :generic  => "\x00",
      :function => "\x01",
      :old      => "\x02",
      :uuid_old => "\x03",
      :uuid     => "\x04",
      :md5      => "\x05",
      :user     => "\x80"
    }

    attr_reader :data, :type

    def initialize(data="", type=:generic)
      @data = data
      @type = type
    end

    def bin_data
      if type == :old
        data_size = [data.bytesize].pack(INT32_PACK)
        [data_size, data].join
      else
        data
      end
    end

    def bson_value
      bson_size = [bin_data.bytesize + 4].pack(INT32_PACK)
      [bson_size, BSON_SUB_TYPES[type], bin_data].join
    end

    def ==(other)
      BSON::Binary === other && data == other.data && type == other.type
    end
    alias eql? ==

    def inspect
      "#<#{self.class.name} type=#{type.inspect} length=#{data.bytesize}>"
    end

    def to_s
      data.to_s
    end

    def self.from_bson(bson)
      length = bson.read(4).unpack(INT32_PACK).first
      type = BSON_SUB_TYPES.invert[bson.read(1)]

      if type == :old
        size -= 4
        bson.read(4)
      end

      data = bson.read(length)
      new(data, type)
    end
  end
end