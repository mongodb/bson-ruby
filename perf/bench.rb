# Copyright (C) 2009-2013 MongoDB Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require "benchmark"
require "ruby-prof"

def benchmark!
  count = 1_000_000
  Benchmark.bm do |bench|

    document = BSON::Document.new(field1: 'testing', field2: 'testing')
    embedded = 5.times.map do |i|
      BSON::Document.new(field1: 10, field2: 'test')
    end
    document[:embedded] = embedded

    bench.report("Document#to_bson ------>") do
      count.times { document.to_bson }
    end

    # bench.report("Binary#to_bson -------->") do
      # count.times { BSON::Binary.new("test", :generic).to_bson }
    # end

    # bench.report("Code#to_bson ---------->") do
      # count.times { BSON::Code.new("this.value = 1").to_bson }
    # end

    # bench.report("FalseClass#to_bson ---->") do
      # count.times { false.to_bson }
    # end

    # bench.report("Float#to_bson --------->") do
      # count.times { 1.131312.to_bson }
    # end

    # bench.report("Integer#to_bson ------->") do
      # count.times { 1024.to_bson }
    # end

    # bench.report("MaxKey#to_bson -------->") do
      # count.times { BSON::MaxKey.new.to_bson }
    # end

    # bench.report("MinKey#to_bson -------->") do
      # count.times { BSON::MinKey.new.to_bson }
    # end

    # bench.report("ObjectId#to_bson ------>") do
      # count.times { BSON::ObjectId.new.to_bson }
    # end

    # bench.report("ObjectId#to_s --------->") do
      # object_id = BSON::ObjectId.new
      # count.times { object_id.to_s }
    # end

    # bench.report("Regexp#to_bson -------->") do
      # count.times { %r{\d+}.to_bson }
    # end

    # bench.report("String#to_bson -------->") do
      # count.times { "testing".to_bson }
    # end

    # bench.report("Symbol#to_bson -------->") do
      # count.times { "testing".to_bson }
    # end

    # bench.report("Time#to_bson ---------->") do
      # count.times { Time.new.to_bson }
    # end

    # bench.report("TrueClass#to_bson ----->") do
      # count.times { true.to_bson }
    # end

    # boolean_bytes = true.to_bson
    # bench.report("Boolean#from_bson ----->") do
      # count.times { BSON::Boolean.from_bson(StringIO.new(boolean_bytes)) }
    # end

    # int32_bytes = 1024.to_bson
    # bench.report("Int32#from_bson ------->") do
      # count.times { BSON::Int32.from_bson(StringIO.new(int32_bytes)) }
    # end

    # int64_bytes = (BSON::Integer::MAX_32BIT + 1).to_bson
    # bench.report("Int64#from_bson ------->") do
      # count.times { BSON::Int64.from_bson(StringIO.new(int64_bytes)) }
    # end

    # float_bytes = 1.23131.to_bson
    # bench.report("Float#from_bson ------->") do
      # count.times { Float.from_bson(StringIO.new(float_bytes)) }
    # end

    # binary_bytes = BSON::Binary.new("test", :generic).to_bson
    # bench.report("Binary#from_bson ------>") do
      # count.times { BSON::Binary.from_bson(StringIO.new(binary_bytes)) }
    # end

    # code_bytes = BSON::Code.new("this.value = 1").to_bson
    # bench.report("Code#from_bson -------->") do
      # count.times { BSON::Code.from_bson(StringIO.new(code_bytes)) }
    # end

    # false_bytes = false.to_bson
    # bench.report("Boolean#from_bson ----->") do
      # count.times { BSON::Boolean.from_bson(StringIO.new(false_bytes)) }
    # end

    # max_key_bytes = BSON::MaxKey.new.to_bson
    # bench.report("MaxKey#from_bson ------>") do
      # count.times { BSON::MaxKey.from_bson(StringIO.new(max_key_bytes)) }
    # end

    # min_key_bytes = BSON::MinKey.new.to_bson
    # bench.report("MinKey#from_bson ------>") do
      # count.times { BSON::MinKey.from_bson(StringIO.new(min_key_bytes)) }
    # end

    # object_id_bytes = BSON::ObjectId.new.to_bson
    # bench.report("ObjectId#from_bson ---->") do
      # count.times { BSON::ObjectId.from_bson(StringIO.new(object_id_bytes)) }
    # end

    # regex_bytes = %r{\d+}.to_bson
    # bench.report("Regexp#from_bson ------>") do
      # count.times { Regexp.from_bson(StringIO.new(regex_bytes)) }
    # end

    # string_bytes = "testing".to_bson
    # bench.report("String#from_bson ------>") do
      # count.times { String.from_bson(StringIO.new(string_bytes)) }
    # end

    # symbol_bytes = "testing".to_bson
    # bench.report("Symbol#from_bson ------>") do
      # count.times { Symbol.from_bson(StringIO.new(symbol_bytes)) }
    # end

    # time_bytes = Time.new.to_bson
    # bench.report("Time#from_bson -------->") do
      # count.times { Time.from_bson(StringIO.new(time_bytes)) }
    # end

    # doc_bytes = document.to_bson
    # bench.report("Document#from_bson ---->") do
      # count.times { BSON::Document.from_bson(StringIO.new(doc_bytes)) }
    # end
  end
end

def profile!
  count = 1_000

  document = BSON::Document.new(field1: 'testing', field2: 'testing')
  embedded = 5.times.map do |i|
    BSON::Document.new(field1: 10, field2: 'test')
  end
  document[:embedded] = embedded

  document_serialization = RubyProf.profile do
    count.times { document.to_bson }
  end

  doc_bytes = document.to_bson
  document_deserialization = RubyProf.profile do
    count.times { BSON::Document.from_bson(StringIO.new(doc_bytes)) }
  end

  RubyProf::GraphPrinter.new(document_serialization).print($stdout)
  RubyProf::GraphPrinter.new(document_deserialization).print($stdout)
end
