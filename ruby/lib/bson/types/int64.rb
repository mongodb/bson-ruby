module BSON
  class Int64
    include Element

    def self.from_bson(bson)
      bson.read(8).unpack(INT64_PACK).first
    end
  end
end