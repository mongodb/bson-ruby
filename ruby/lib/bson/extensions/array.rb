module BSON
  module Extensions
    module Array
      include BSON::Element

      BSON_TYPE = "\x04"

      def elements
        to_enum.with_index(1).inject({}) do |array, (element, index)|
          array[index] = element
          array
        end
      end

      def bson_value
        elements.bson_value
      end

      module ClassMethods
        def from_bson(bson)
        end
      end
    end
  end
end
