require 'bson/types/code'
require 'bson/types/code_w_scope'
require 'bson/types/min_key'
require 'bson/types/max_key'
require 'bson/types/binary'
require 'bson/types/document'
require 'bson/types/timestamp'
require 'bson/types/integer_64'
require 'bson/types/object_id'
require 'bson/types/undefined'
require 'bson/types/db_pointer'

module BSON
  module Types
    MAP = {}
    MAP[1]  = Float
    MAP[2]  = String
    MAP[3]  = Hash
    MAP[4]  = Array
    MAP[5]  = Binary
    # MAP[6]  = undefined - deprecated
    MAP[7]  = ObjectId
    MAP[8]  = TrueClass
    MAP[9]  = Time
    MAP[10] = NilClass
    MAP[11] = Regexp
    # MAP[12] = db pointer - deprecated
    MAP[13] = Code
    MAP[14] = Symbol
    MAP[15] = CodeWithScope
    MAP[16] = Integer
    MAP[17] = Timestamp
    MAP[18] = Integer64
    MAP[127] = MaxKey
    MAP[255] = MinKey

    FLOAT = 0x01.freeze
    STRING = 0x02.freeze
    HASH = 0x03.freeze
    ARRAY = 0x04.freeze
    BINARY = 0x05.freeze
    OBJECT_ID = 0x07.freeze
    BOOLEAN = 0x08.freeze
    TIME = 0x09.freeze
    NULL = 0x0A.freeze
    REGEX = 0x0B.freeze
    DB_POINTER = 0x0C.freeze
    CODE = 0x0D.freeze
    SYMBOL = 0x0E.freeze
    CODE_WITH_SCOPE = 0x0F.freeze
    INT32 = 0x10.freeze
    TIMESTAMP = 0x11.freeze
    INT64 = 0x12.freeze
    MAX_KEY = 0x7F.freeze
    MIN_KEY = 0xFF.freeze

    TRUE = 1.chr.freeze
  end
end