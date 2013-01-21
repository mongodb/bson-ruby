module BSON
  module Extensions
    module NilClass
      BSON_TYPE = "\x0A"

      def to_bson
      end

      module ClassMethods
        def from_bson(bson)
          nil
        end
      end
    end
  end
end