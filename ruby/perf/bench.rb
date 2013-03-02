$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require "benchmark"

def benchmark!
  count = 1_000_000
  Benchmark.bm do |bench|

    bench.report("Binary#to_bson -------->") do
      count.times { BSON::Binary.new(:generic, "test").to_bson }
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
      count.times { BSON::MinKey.new.to_bson }
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
  end
end
