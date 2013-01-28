require 'digest/md5'
require 'socket'

module BSON
  class ObjectId
    include Element
    include Comparable

    attr_reader :data

    BSON_TYPE = "\x07"

    def initialize(data = nil)
      @data = data || @@generator.next
    end

    def bson_value
      data
    end

    def to_s
      data.unpack("H*").first
    end

    def inspect
      "BSON::ObjectId('#{to_s}')"
    end

    def hash
      data.hash
    end

    def to_a
      data.dup
    end

    def <=>(other)
      data <=> other.data
    end

    def to_json
      "{\"$oid\": \"#{to_s}\"}"
    end

    def self.from_string(string)
      new([string].pack("H24"))
    end

    def self.from_bson(bson)
      new(bson.read(12))
    end

    class Generator
      def initialize
        @machine_id = Digest::MD5.digest(Socket.gethostname).unpack("N").first
        @mutex = Mutex.new
        @counter = 0
      end

      def next
        @mutex.lock
        begin
          counter = @counter = (@counter + 1) % 0xFFFFFF
        ensure
          @mutex.unlock rescue nil
        end

        generate(Time.new.to_i, counter)
      end

      def process_thread_id
        "#{Process.pid}#{Thread.current.object_id}".hash % 0xFFFF
      end

      def generate(time, counter = 0)
        [time, @machine_id, process_thread_id, counter << 8].pack("N NX lXX NX")
      end
    end

    @@generator = Generator.new
  end
end