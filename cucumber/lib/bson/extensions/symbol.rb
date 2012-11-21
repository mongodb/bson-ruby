module BSON
  module Extensions
    module Symbol
      def __bson_export__(io, key)
        io << Types::SYMBOL
        io << key.to_bson_cstring
        io << to_s.to_bson_string
      end
    end
  end
end