module BSON
  module Extensions
    module Float
      include Element
      
      BSON_TYPE = "\x01"

      def bson_value
        [self].pack(FLOAT_PACK)
      end

      module ClassMethods
        def from_bson(bson)
          bson.read(8).unpack(FLOAT_PACK).first
        end
      end
    end
  end
end