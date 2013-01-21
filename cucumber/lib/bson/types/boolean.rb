module BSON
  class Boolean
    BSON_TYPE = "\x08"
    
    class << self
      def from_bson(io)
        io.readbyte == 1
      end
    end
  end
end