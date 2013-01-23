module BSON
  module Extensions
    module Float
      BSON_TYPE = "\x01"

      def to_bson
        [BSON_TYPE, [self].pack(FLOAT_PACK)]
      end

      module ClassMethods
        def from_bson(bson)
          bson.read(8).unpack(FLOAT_PACK).first
        end
      end
    end
  end
end