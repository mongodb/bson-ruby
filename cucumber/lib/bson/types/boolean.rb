module BSON
  class Boolean
    class << self
      def from_bson(io)
        io.readbyte == 1
      end
    end
  end
end