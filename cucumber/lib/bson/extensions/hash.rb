module BSON
  module Extensions
    module Hash
      BSON_TYPE = "\x03"

      def e_list
        map do |k,v|
          [BSON::Types::get_binary(v), k.to_bson_cstring, v.to_bson].join
        end
      end

      def to_bson
        elements = e_list
        [[bytesize(elements)].pack(INT32_PACK), elements, EOD].join
      end

      def bytesize(e_list)
        e_list.map(&:bytesize).reduce(5, :+)
      end
    end
  end
end