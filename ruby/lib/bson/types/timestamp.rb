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
  end
end