module BSON
  class Timestamp
    BSON_TYPE = "\x11"

    attr_reader :seconds, :increment

    def initialize(seconds, increment)
      @seconds = seconds
      @increment = increment
    end

    def to_bson
      timestamp = [increment.to_bson, seconds.to_bson].join
      [BSON_TYPE, timestamp]
    end
  end
end