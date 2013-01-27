module BSON
  module Extensions
    module Symbol
      include Element

      BSON_TYPE = "\x0E"

      def bson_value
        to_s.to_bson_string
      end

      module ClassMethods
        def from_bson(bson)
          bson.read(*bson.read(4).unpack(INT32_PACK)).from_utf8_binary.chop!.intern
        end
      end
    end
  end
end