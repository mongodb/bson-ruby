module BSON
  module Extensions
    module TrueClass
      BSON_TYPE = "\x08"

      def to_bson
        [BSON_TYPE, "\x01"]
      end
    end
  end
end