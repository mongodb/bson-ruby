module BSON
  class ObjectId
    BSON_TYPE = "\x07"

    def initialize(id)
      @id = id
    end

    def to_bson
      [BSON_TYPE, @id]
    end
  end
end