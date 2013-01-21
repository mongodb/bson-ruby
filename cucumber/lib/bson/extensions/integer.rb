module BSON
  module Extensions
    module Integer
      INT32_MIN = -(1 << 31) + 1
      INT32_MAX =  (1 << 31) - 1

      INT64_MIN = -2**64 / 2
      INT64_MAX =  2**64 / 2 - 1

      def bson_type
        if self >= INT32_MIN && self <= INT32_MAX
          0x10
        elsif self >= INT64_MIN && self <= INT64_MAX
          0x11
        else
          raise RangeError.new("MongoDB can only handle ints up to 8 bytes in size")
        end
      end

      def to_bson
        [self].pack(bson_type == 0x10 ? INT32_PACK : INT64_PACK)
      end
    end
  end
end