module BSON
  class Boolean
    def from_bson(io)
      io.readbyte == 1
    end
  end
end