module Mongo
  module Protocol
    class GetMore
      include Message

      OPCODE = 2005
    end
  end
end
