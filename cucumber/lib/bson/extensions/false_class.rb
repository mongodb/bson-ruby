module BSON
  module Extensions
    module FalseClass
      def __bson_export__(io, key)
        io << Types::BOOLEAN
        io << key.to_bson_cstring
        io << 0x00
      end
    end
  end
end