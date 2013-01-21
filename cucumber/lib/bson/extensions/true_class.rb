module BSON
  module Extensions
    module TrueClass
      BSON_TYPE = "\x08"

      def to_bson
        "\x01"
      end
    end
  end
end