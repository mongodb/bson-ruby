module Mongo
  module Protocol
    class Query
      include Message

      OPCODE = 2004
    end
  end
end
