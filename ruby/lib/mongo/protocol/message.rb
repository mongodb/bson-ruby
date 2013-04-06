module Mongo
  module Protocol
    module Message
      def fields
        @fields ||= []
      end

      def int32(number)
        [number].pack(BSON::INT32_PACK)
      end

      def request_id
        0
      end

      def response_to
        0
      end

      def header
        [
          int32(message.length),
          int32(request_id),
          int32(response_to),
          self.class.const_get(:OP_CODE)
        ].join
      end

      def message
        fields.join
      end

      def to_bson(encoded = ''.force_encoding(BINARY))
        encoded << header
        encoded << message
      end
    end
  end
end
