require 'bson/extensions'
require 'bson/types'

module BSON
  EOD = NULL_BYTE = "\x00"

  INT32_PACK = 'l<'
  INT64_PACK = 'q<'
  FLOAT_PACK = 'E'

  SIZE_SPACER = [0].pack(INT32_PACK)

  BINARY_ENCODING = Encoding.find 'binary'
  UTF8_ENCODING   = Encoding.find 'utf-8'

  class << self
    def serialize(document, io = "")
      document.to_bson(io, document)
    end

    def deserialize(io)
      Document.from_bson(io)
    end
  end
end