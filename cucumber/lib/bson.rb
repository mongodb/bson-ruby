require 'bson/extensions'
require 'bson/types'

module BSON
  EOD = NULL_BYTE = "\x00"

  INT32_PACK = 'l<'
  INT64_PACK = 'q<'
  FLOAT_PACK = 'E'

  BINARY_ENCODING = Encoding.find 'binary'
  UTF8_ENCODING   = Encoding.find 'utf-8'

  class << self
    def serialize(document)
      document.to_bson
    end

    def deserialize(io)
      Document.from_bson(io)
    end
  end
end