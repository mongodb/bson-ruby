module BSON
  class Document < Hash
    include Element

    def to_bson
      bson_value
    end

    def initialize
      super
      self.default_proc= proc { |hash, key| hash.key?(key.to_s) ? hash[key.to_s] : nil }
    end

    def self.from_bson(bson, document = new)
      length = bson.read(4)

      while (type = bson.readbyte).chr != EOD
        e_name = bson.gets(NULL_BYTE).from_utf8_binary.chop!.intern
        document[e_name] = Types::MAP[type].from_bson(bson)
      end

      document
    end
  end
end