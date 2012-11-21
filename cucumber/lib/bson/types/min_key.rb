module BSON
  class MinKey
    def __bson_export__(io, key)
      io << Types::MIN_KEY
      io << key.to_bson_cstring
    end
  end
end