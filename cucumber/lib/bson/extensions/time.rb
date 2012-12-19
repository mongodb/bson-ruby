module BSON
  module Extensions
    module Time
      def to_bson(io, key)
        io << Types::TIME
        io << key.to_bson_cstring
        io << [(to_i * 1000) + (usec / 1000)].pack(INT64_PACK)
      end

      module ClassMethods
        def from_bson
        end
      end
    end
  end
end