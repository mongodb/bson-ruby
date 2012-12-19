module BSON
  module Extensions
    module TrueClass
      def to_bson(io, key)
        io << Types::BOOLEAN
        io << key.to_bson_cstring
        io << Types::TRUE
      end
    end
  end
end