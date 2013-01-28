module BSON
  class Timestamp
    include Element

    BSON_TYPE = "\x11"

    attr_reader :seconds, :increment

    def initialize(seconds, increment)
      @seconds = seconds
      @increment = increment
    end

    def bson_value
      [increment.to_bson, seconds.to_bson].join
    end

    def self.from_bson
      new(*io.read(8).unpack(INT32_PACK * 2).reverse)
    end
  end
end