module BSON
  module Extensions
    module FalseClass
      BSON_TYPE = "\x08"

      def to_bson
        [BSON_TYPE, "\x00"]
      end
    end
  end
end