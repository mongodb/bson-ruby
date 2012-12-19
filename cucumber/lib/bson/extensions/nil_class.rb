module BSON
  module Extensions
    module NilClass
      def to_bson(io, key)
        io << Types::NULL
        io << key.to_bson_cstring
      end

      module ClassMethods
        def from_bson(io)
          nil
        end
      end
    end
  end
end