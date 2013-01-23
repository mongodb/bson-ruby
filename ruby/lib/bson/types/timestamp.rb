module BSON
  class Timestamp
    BSON_TYPE = "\x11"

    def initialize(ts)
      @ts = ts
    end

    def to_bson
      [BSON_TYPE, @ts]
    end
  end
end