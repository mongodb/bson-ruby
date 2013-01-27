module Mongo
  module Protocol
    class Reply
      include Message

      OPCODE = 1
    end
  end
end
