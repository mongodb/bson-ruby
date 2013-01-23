module BSON
  class Code
    attr_reader :code, :scope

    def initialize(code, scope={})
      @code = code
      @scope = scope
    end

    def scoped?
      !scope.empty?
    end

    def bson_type
      scoped? ? "\x0F" : "\x0D"
    end

    def to_bson
      if scoped?
        data = code.to_utf8_binary
        data_size = [data.bytesize+1].pack(INT32_PACK)

        [bson_type, [data_size, data, NULL_BYTE].join]
      else
        [bson_type, code.to_bson_string]
      end
    end
  end
end