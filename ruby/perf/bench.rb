$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require "benchmark"

def benchmark!
  count = 1_000_000
  Benchmark.bm do |bench|

    bench.report("String#to_bson -->") do
      count.times do
        "testing".to_bson
      end
    end

    bench.report("Integer#to_bson ->") do
      count.times do
        1024.to_bson
      end
    end
  end
end
