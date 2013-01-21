module BSON
  module Extensions
    module Float
      BSON_TYPE = "\x01"

      def to_bson
        [self].pack(FLOAT_PACK)
      end

      module ClassMethods
        def from_bson(bson)
          bson.unpack(FLOAT_PACK).first
        end
      end
    end
  end
end