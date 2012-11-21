module BSON
  class MaxKey
    def __bson_export__(io, key)
      io << Types::MAX_KEY
      io << key.to_bson_cstring
    end
  end
end