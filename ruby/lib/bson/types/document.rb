module BSON
  class Document < Hash
    include BSON::Element

    def to_bson
      bson_value
    end

    def self.from_bson(bson, document = new)
      length = bson.read(4)

      while(bson_type = bson.readbyte) != 0
        e_name = bson.gets(NULL_BYTE).from_utf8_binary.chop!
        document[e_name] = Types::MAP[bson_type].from_bson(bson)
      end

      document
    end
  end
end