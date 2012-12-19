module BSON
  module Extensions
    module Time
      def to_bson(io, key)
        io << Types::DATETIME
        io << key.to_bson_cstring
        io << [(to_i * 1000) + (usec / 1000)].pack(INT64_PACK)
      end

      module ClassMethods
        def from_bson(io)
          seconds, fragment = io.read(8).unpack(INT64_PACK)[0].divmod 1000
          at(seconds, fragment * 1000).utc
        end
      end
    end
  end
end