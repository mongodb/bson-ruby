module BSON
  class MaxKey
    def to_bson(io, key)
      io << Types::MAX_KEY
      io << key.to_bson_cstring
    end
  end
end