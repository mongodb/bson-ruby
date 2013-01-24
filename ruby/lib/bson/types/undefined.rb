module BSON
  class Undefined
    extend BSON::Element

    BSON_TYPE ="\x06"

    def self.to_bson
      [BSON_TYPE]
    end
  end
end