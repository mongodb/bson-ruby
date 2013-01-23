module BSON
  class Document < Hash
    def self.from_bson(io, document = new)
      length = io.read(4)

      while(bson_type = io.readbyte) != 0
        e_name = io.gets(NULL_BYTE).from_utf8_binary.chop!
        document[e_name] = Types::MAP[bson_type].from_bson(io)
      end

      document
    end
  end
end