module BSON
  class MinKey
    class << self
      def to_bson(io, key)
        io << Types::MIN_KEY
        io << key.to_bson_cstring
      end 
      
      def from_bson(io)
        self
      end
    end
  end
end