module BSON
  module Extensions
    module FalseClass
      include BSON::Element

      BSON_TYPE = "\x08"

      def bson_value
        "\x00"
      end
    end
  end
end