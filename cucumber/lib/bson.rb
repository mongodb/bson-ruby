require 'bson/extensions'
require 'bson/types'

module BSON
  EOD = NULL_BYTE = "\x00".freeze

  INT32_PACK = 'l<'.freeze
  INT64_PACK = 'q<'.freeze
  FLOAT_PACK = 'E'.freeze

  SIZE_SPACER = [0].pack(INT32_PACK).freeze

  BINARY_ENCODING = Encoding.find 'binary'
  UTF8_ENCODING   = Encoding.find 'utf-8'

  class << self
    def deserialize(io)
      obj.__bson_import__(io)
    end

    def serialize(obj, io = "")
      obj.__bson_export__(io)
    end
  end
end