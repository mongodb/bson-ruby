module BSON
  module Extensions
    module Time
      def __bson_export__(io, key)
        io << Types::TIME
        io << key.to_bson_cstring
        io << [(to_i * 1000) + (usec / 1000)].pack(INT64_PACK)
      end
    end
  end
end