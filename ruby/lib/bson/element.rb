module BSON
  module Element
    def to_bson
      [bson_type, bson_value]
    end

    def bson_type
      self.class.const_get(:BSON_TYPE)
    end

    def bson_value
      self
    end

    def self.from_bson(bson)
      self
    end
  end
end