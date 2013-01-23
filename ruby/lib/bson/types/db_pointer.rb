module BSON
  class DBPointer
    BSON_TYPE = "\x0C"

    def initialize(pointer)
      @pointer = pointer
    end

    def to_bson
      [BSON_TYPE, @pointer]
    end
  end
end
