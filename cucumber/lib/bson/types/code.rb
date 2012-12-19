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

    def to_bson(io, key)
      if scoped?
        io << Types::CODE_WITH_SCOPE
        io << key.to_bson_cstring

        code_start = io.bytesize

        io << START_LENGTH

        data = code.to_utf8_binary
        io << [data.bytesize+1].pack(INT32_PACK)
        io << data
        io << NULL_BYTE

        scope.__bson_dump__(io)

        io[code_start, 4] = [io.bytesize - code_start].pack(INT32_PACK)
      else
        io << Types::CODE
        io << key.to_bson_cstring
        io << code.to_bson_string
      end
    end
  end
end