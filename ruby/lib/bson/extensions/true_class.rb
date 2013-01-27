module BSON
  module Extensions
    module TrueClass
      include Element

      BSON_TYPE = "\x08"

      def bson_value
        "\x01"
      end
    end
  end
end