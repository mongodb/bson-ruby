module BSON
  module Extensions
    module Float
      def to_bson(io, key)
        io << Types::FLOAT
        io << key.to_bson_cstring
        io << [self].pack(FLOAT_PACK)
      end

      module ClassMethods
        def from_bson(io)
          io.read(8).unpack(FLOAT_PACK).first
        end
      end
    end
  end
end