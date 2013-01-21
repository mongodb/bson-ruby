$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'benchmark'
require 'bson'

n = 1_000_000
small_doc = {"small" => "doc"}

Benchmark.bmbm do |x|
  x.report("small") { n.times do; BSON.serialize(small_doc); end }
end