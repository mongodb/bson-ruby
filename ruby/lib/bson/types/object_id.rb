module BSON
  class ObjectId
    include Element

    BSON_TYPE = "\x07"

    def initialize(id)
      @id = id
    end

    def self.from_string(string)
      new([string].pack("H24"))
    end

    def bson_value
      @id
    end
  end
end