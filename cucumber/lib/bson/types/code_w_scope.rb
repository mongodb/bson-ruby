module BSON
  class CodeWithScope
    def self.__bson_load__(io)
      io.read 4 # swallow the length

      code = io.read(*io.read(4).unpack(INT32_PACK)).from_utf8_binary.chop!
      scope = BSON::Document.deserialize(io)

      Code.new code, scope
    end
  end
end