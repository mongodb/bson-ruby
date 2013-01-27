module BSON
  module MaxKey
    extend Element

    BSON_TYPE = "\x7F"

    def self.bson_value
      nil
    end

    def self.bson_type
      BSON_TYPE
    end
 
    def self.from_bson(bson)
      self
    end
  end
end