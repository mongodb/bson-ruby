module BSON
  class Undefined
    extend BSON::Element

    BSON_TYPE ="\x06"

    def self.bson_value
      ""
    end

    def self.bson_type
      BSON_TYPE
    end

    def self.from_bson(bson)
      self
    end
  end
end