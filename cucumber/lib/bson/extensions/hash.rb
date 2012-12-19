module BSON
  module Extensions
    module Hash
      def to_bson(io = "", key = nil)
        #if key
        #  io << Types::HASH
        #  io << key.to_bson_cstring
        #end

        start = io.bytesize

        io << SIZE_SPACER
        each {|k,v| v.to_bson(io, k.to_s)}
        io << EOD

        stop = io.bytesize

        io[start, 4] = [stop - start].pack INT32_PACK
        
        io
      end

      module ClassMethods
        def from_bson(io, document = new)
          length = io.read(4)

          while(bson_type = io.readbyte) != 0
            e_name = io.gets(NULL_BYTE).from_utf8_binary.chop!
            document[e_name] = Types::MAP[bson_type].from_bson(io)
          end

          document
        end
      end
    end
  end
end