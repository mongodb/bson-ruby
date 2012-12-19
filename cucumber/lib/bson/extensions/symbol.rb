module BSON
  module Extensions
    module Symbol
      def to_bson(io, key)
        io << Types::SYMBOL
        io << key.to_bson_cstring
        io << to_s.to_bson_string
      end

      module ClassMethods
        def from_bson(io)
          io.read(*io.read(4).unpack(INT32_PACK)).from_utf8_binary.chop!.intern
        end
      end
    end
  end
end