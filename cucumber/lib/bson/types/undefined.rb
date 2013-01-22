module BSON
  class Undefined
    BSON_TYPE ="\x06"

    def to_bson
      [BSON_TYPE, nil]
    end
  end
end