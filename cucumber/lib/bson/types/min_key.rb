module BSON
  class MinKey
    def to_bson(io, key)
      io << Types::MIN_KEY
      io << key.to_bson_cstring
    end
  end
end