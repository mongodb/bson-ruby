module BSON
  module MinKey
    extend Element

    BSON_TYPE = "\xFF"

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