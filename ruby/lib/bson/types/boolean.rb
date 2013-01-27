module BSON
  class Boolean
    include Element

    BSON_TYPE = "\x08"
    
    def self.from_bson(io)
      io.readbyte == 1
    end
  end
end