module BSON
  module Extensions
    module NilClass
      include BSON::Element

      BSON_TYPE = "\x0A"

      module ClassMethods
        def from_bson(bson)
          nil
        end
      end
    end
  end
end