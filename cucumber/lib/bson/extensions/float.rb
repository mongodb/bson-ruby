module BSON
  module Extensions
    module Float
      def __bson_import__
      end

      def __bson_export__(io, key)
        io << Types::FLOAT
        io << key.to_bson_cstring
        io << [self].pack(FLOAT_PACK)
      end
    end
  end
end