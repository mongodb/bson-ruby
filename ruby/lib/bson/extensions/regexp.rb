module BSON
  module Extensions
    module Regexp
      include BSON::Element

      BSON_TYPE = "\x0B"

      def bson_option
        'i'  if (options & ::Regexp::IGNORECASE) != 0
        'ms' if (options & ::Regexp::MULTILINE) != 0
        'x'  if (options & ::Regexp::EXTENDED) != 0
      end

      def bson_value
        [source.to_bson_cstring, bson_option, NULL_BYTE].join
      end

      module ClassMethods
        def from_bson(io)
          pattern = io.gets(NULL_BYTE).from_utf8_binary.chop!
          options = 0
          while (option = io.readbyte) != 0
            case option
            when 105 # 'i'
              options |= ::Regexp::IGNORECASE
            when 109, 115 # 'm', 's'
              options |= ::Regexp::MULTILINE
            when 120 # 'x'
              options |= ::Regexp::EXTENDED
            end
          end

          new(pattern, options)
        end
      end
    end
  end
end