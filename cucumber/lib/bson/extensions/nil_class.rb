module BSON
  module Extensions
    module NilClass
      def __bson_export__(io, key)
        io << Types::NULL
        io << key.to_bson_cstring
      end
    end
  end
end