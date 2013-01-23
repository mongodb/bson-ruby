require 'bson/types/code'
require 'bson/types/min_key'
require 'bson/types/max_key'
require 'bson/types/binary'
require 'bson/types/document'
require 'bson/types/timestamp'
require 'bson/types/int32'
require 'bson/types/int64'
require 'bson/types/object_id'
require 'bson/types/undefined'
require 'bson/types/db_pointer'
require 'bson/types/boolean'

module BSON
  module Types
    MAP = {}
    MAP[1]   = Float
    MAP[2]   = String
    MAP[3]   = Document
    MAP[4]   = Array
    MAP[5]   = Binary
    MAP[6]   = Undefined # deprecated
    MAP[7]   = ObjectId
    MAP[8]   = Boolean
    MAP[9]   = Time
    MAP[10]  = NilClass
    MAP[11]  = Regexp
    MAP[12]  = DBPointer # deprecated
    MAP[13]  = Code
    MAP[14]  = Symbol
    MAP[15]  = Code
    MAP[16]  = Int32
    MAP[17]  = Timestamp
    MAP[18]  = Int64
    MAP[127] = MaxKey
    MAP[255] = MinKey
  end
end