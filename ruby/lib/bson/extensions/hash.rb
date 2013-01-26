module BSON
  module Extensions
    module Hash
      include BSON::Element

      BSON_TYPE = "\x03"

      def elements
        map do |e_name, value|
          type, value = value.to_bson
          [type, e_name.to_s.to_bson_cstring, value].join
        end
      end

      def bson_value
        e_list = elements
        size = [bytesize(e_list)].pack(INT32_PACK)
        [size, e_list, EOD].join
      end

      def bytesize(e_list)
        e_list.map(&:bytesize).reduce(5, :+)
      end
    end
  end
end