module BSON
  class DBPointer
    BSON_TYPE = "\x0C"

    attr_reader :ns, :id

    def initialize(ns, id)
      @ns = ns
      @id = id
    end

    def to_bson
      pointer = [ns.to_bson, id.to_bson].join
      [BSON_TYPE, pointer]
    end
  end
end
