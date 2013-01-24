module BSON
  class DBPointer
    include BSON::Element

    BSON_TYPE = "\x0C"

    attr_reader :ns, :id

    def initialize(ns, id)
      @ns = ns
      @id = id
    end

    def bson_value
      [ns.to_bson, id.to_bson].join
    end
  end
end
