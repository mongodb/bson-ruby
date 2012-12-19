module BSON
  module Int64
    def self.from_bson(io)
      io.read(8).unpack(INT64_PACK)[0]
    end
  end
end