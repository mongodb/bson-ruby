module BSON
  module Extensions
    module Integer
      INT32_MIN = -(1 << 31) + 1
      INT32_MAX =  (1 << 31) - 1

      INT64_MIN = -2**64 / 2
      INT64_MAX =  2**64 / 2 - 1

      def to_bson(io, key)
        if self >= INT32_MIN && self <= INT32_MAX
          io << Types::INT32
          io << key.to_bson_cstring
          io << [self].pack(INT32_PACK)
        elsif self >= INT64_MIN && self <= INT64_MAX
          io << Types::INT64
          io << key.to_bson_cstring
          io << [self].pack(INT64_PACK)
        else
          raise RangeError.new("MongoDB can only handle ints up to 8 bytes in size")
        end
      end
    end
  end
end