module BSON
  module Extensions
    module TrueClass
      def __bson_export__(io, key)
        io << Types::BOOLEAN
        io << key.to_bson_cstring
        io << 0x01
      end
    end
  end
end