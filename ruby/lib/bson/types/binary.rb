module BSON
  class Binary
    include BSON::Element

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

    def bson_value
      if type == :old
        [@data.bytesize + 4].pack(INT32_PACK)
        BSON_SUB_TYPES[@type]
        [@data.bytesize].pack(INT32_PACK)
        @data
      else
        [@data.bytesize].pack(INT32_PACK)
        BSON_SUB_TYPES[@type]
        @data
      end
    end

    def ==(other)
      BSON::Binary === other && data == other.data && type == other.type
    end
    alias eql? ==

    class << self
      def from_bson(bson)
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

    def inspect
      "#<#{self.class.name} type=#{type.inspect} length=#{data.bytesize}>"
    end

    def to_s
      data.to_s
    end
  end
end