module BSON
  class MaxKey
    extend BSON::Element

    BSON_TYPE = "\x7F"
 
    def self.from_bson(bson)
      self
    end

    def self.to_bson
      [BSON_TYPE]
    end
  end
end