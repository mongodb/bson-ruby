module BSON
  module Extensions
    module FalseClass
      BSON_TYPE = "\x08"

      def to_bson
        "\x00"
      end
    end
  end
end