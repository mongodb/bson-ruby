module BSON
  class Integer64
    def self.__bson_load__(io)
      io.read(8).unpack(INT64_PACK)[0]
    end
  end
end