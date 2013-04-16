$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require "benchmark"

def benchmark!
  count = 2_000_000
  Benchmark.bm do |bench|

    bench.report("Binary#to_bson -------->") do
      count.times { BSON::Binary.new("test", :generic).to_bson }
    end

    bench.report("Code#to_bson ---------->") do
      count.times { BSON::Code.new("this.value = 1").to_bson }
    end

    bench.report("FalseClass#to_bson ---->") do
      count.times { false.to_bson }
    end

    bench.report("Float#to_bson --------->") do
      count.times { 1.131312.to_bson }
    end

    bench.report("Integer#to_bson ------->") do
      count.times { 1024.to_bson }
    end

    bench.report("MaxKey#to_bson -------->") do
      count.times { BSON::MaxKey.new.to_bson }
    end

    bench.report("MinKey#to_bson -------->") do
      count.times { BSON::MinKey.new.to_bson }
    end

    bench.report("ObjectId#to_bson ------>") do
      count.times { BSON::ObjectId.new.to_bson }
    end

    bench.report("ObjectId#to_s --------->") do
      object_id = BSON::ObjectId.new
      count.times { object_id.to_s }
    end

    bench.report("Regexp#to_bson -------->") do
      count.times { %r{\d+}.to_bson }
    end

    bench.report("String#to_bson -------->") do
      count.times { "testing".to_bson }
    end

    bench.report("Symbol#to_bson -------->") do
      count.times { "testing".to_bson }
    end

    bench.report("Time#to_bson ---------->") do
      count.times { Time.new.to_bson }
    end

    bench.report("TrueClass#to_bson ----->") do
      count.times { true.to_bson }
    end

    int32_bytes = 1024.to_bson
    bench.report("Int32#from_bson ------->") do
      count.times { BSON::Int32.from_bson(StringIO.new(int32_bytes)) }
    end

    int64_bytes = (BSON::Integer::MAX_32BIT + 1).to_bson
    bench.report("Int64#from_bson ------->") do
      count.times { BSON::Int64.from_bson(StringIO.new(int64_bytes)) }
    end

    float_bytes = 1.23131.to_bson
    bench.report("Float#from_bson ------->") do
      count.times { Float.from_bson(StringIO.new(float_bytes)) }
    end
  end
end
