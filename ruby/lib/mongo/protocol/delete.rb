module Mongo
  module Protocol
    class Delete
      include Message

      OPCODE = 2006
    end
  end
end
