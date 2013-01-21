module BSON
  module Extensions
    module Array
      BSON_TYPE = "\x04"

      def to_bson
      end

      module ClassMethods
        def from_bson(bson)
        end
      end
    end
  end
end
