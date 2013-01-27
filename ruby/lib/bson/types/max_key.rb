module BSON
  module MaxKey
    extend BSON::Element

    BSON_TYPE = "\x7F"

    def self.bson_value
      String.new
    end

    def self.bson_type
      BSON_TYPE
    end
 
    def self.from_bson(bson)
      self
    end
  end
end