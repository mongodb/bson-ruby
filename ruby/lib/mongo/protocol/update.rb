module Mongo
  module Protocol
    class Update
      include Message

      OPCODE = 2001
    end
  end
end
