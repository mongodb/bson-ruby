module Mongo
  module Protocol
    class KillCursors
      include Message

      OPCODE = 2007
    end
  end
end
