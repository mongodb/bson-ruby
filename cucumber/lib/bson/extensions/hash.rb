module BSON
  module Extensions
    module Hash
      def __bson_import__
      end

      def __bson_export__(io = "", key = nil)
        #if key
        #  io << Types::HASH
        #  io << key.to_bson_cstring
        #end

        start = io.bytesize

        io << SIZE_SPACER
        each {|k,v| v.__bson_export__(io, k.to_s)}
        io << EOD

        stop = io.bytesize

        io[start, 4] = [stop - start].pack INT32_PACK
        
        io
      end
    end
  end
end