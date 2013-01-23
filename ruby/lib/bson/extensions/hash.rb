module BSON
  module Extensions
    module Hash
      BSON_TYPE = "\x03"

      def elements
        map do |e_name, value|
          bson_type, bson_value = value.to_bson
          [bson_type, e_name.to_bson_cstring, bson_value].join
        end
      end

      def to_bson
        e_list = elements
        size = [bytesize(elements)].pack(INT32_PACK)
        document = [size, e_list, EOD].join
        [BSON_TYPE, document]
      end

      def bytesize(e_list)
        e_list.map(&:bytesize).reduce(5, :+)
      end
    end
  end
end