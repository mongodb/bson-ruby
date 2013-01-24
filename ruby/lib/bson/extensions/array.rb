module BSON
  module Extensions
    module Array
      include BSON::Element

      BSON_TYPE = "\x04"

      module ClassMethods
        def from_bson(bson)
        end
      end
    end
  end
end
