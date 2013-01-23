module BSON
  class Int32
    def self.from_bson(io)
      io.read(4).unpack(INT32_PACK)[0]
    end
  end
end