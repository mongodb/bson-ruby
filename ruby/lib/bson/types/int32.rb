module BSON
  class Int32
    def self.from_bson(bson)
      bson.read(4).unpack(INT32_PACK).first
    end
  end
end