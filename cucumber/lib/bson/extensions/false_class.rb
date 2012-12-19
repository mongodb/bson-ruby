module BSON
  module Extensions
    module FalseClass
      def to_bson(io, key)
        io << Types::BOOLEAN
        io << key.to_bson_cstring
        io << Types::FALSE
      end
    end
  end
end