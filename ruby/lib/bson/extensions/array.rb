module BSON
  module Extensions
    module Array
      include BSON::Element

      BSON_TYPE = "\x04"

      def elements
        to_enum.each_with_index.inject({}) do |array, (element, index)|
          array[index] = element
          array
        end
      end

      def bson_value
        elements.bson_value
      end

      module ClassMethods
        def from_bson(bson, array = new)
          bson.read(4)

          while (type = bson.readbyte).chr != NULL_BYTE
            bson.gets(NULL_BYTE)
            array << Types::MAP[type].from_bson(bson)
          end

          array
        end
      end
    end
  end
end
