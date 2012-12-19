module BSON
  class Binary
    BSON_SUB_TYPES = {
      :generic  => 0x00,
      :function => 0x01,
      :old      => 0x02,
      :uuid_old => 0x03,
      :uuid     => 0x04,
      :md5      => 0x05,
      :user     => 0x80
    }

    attr_reader :data, :type

    def initialize(data, type=:generic)
      @data = data
      @type = type
    end

    def to_bson(io, key)
      io << Types::BINARY
      io << key.to_bson_cstring
      if type == :old
        io << [data.bytesize + 4].pack(INT32_PACK)
        io << BSON_SUB_TYPES[type]
        io << [data.bytesize].pack(INT32_PACK)
        io << data
      else
        io << [data.bytesize].pack(INT32_PACK)
        io << BSON_SUB_TYPES[type]
        io << data
      end
    end

    def from_bson
    end


    def inspect
      "#<#{self.class.name} type=#{type.inspect} length=#{data.bytesize}>"
    end

    def to_s
      data.to_s
    end
  end
end