# Copyright (C) 2009-2019 MongoDB Inc.
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

    bench.report("Binary#to_bson -------->") do
      count.times { BSON::Binary.new("test", :generic).to_bson }
    end

    bench.report("Code#to_bson ---------->") do
      count.times { BSON::Code.new("this.value = 1").to_bson }
    end

    big_decimal = BigDecimal(123)
    bench.report("Decimal128#to_bson ---->") do
      count.times { BSON::Decimal128.new(big_decimal).to_bson }
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

    boolean_bytes = true.to_bson.to_s
    bench.report("Boolean#from_bson ----->") do
      count.times { BSON::Boolean.from_bson(BSON::ByteBuffer.new(boolean_bytes)) }
    end

    int32_bytes = 1024.to_bson.to_s
    bench.report("Int32#from_bson ------->") do
      count.times { BSON::Int32.from_bson(BSON::ByteBuffer.new(int32_bytes)) }
    end

    int64_bytes = (BSON::Integer::MAX_32BIT + 1).to_bson.to_s
    bench.report("Int64#from_bson ------->") do
      count.times { BSON::Int64.from_bson(BSON::ByteBuffer.new(int64_bytes)) }
    end

    float_bytes = 1.23131.to_bson.to_s
    bench.report("Float#from_bson ------->") do
      count.times { Float.from_bson(BSON::ByteBuffer.new(float_bytes)) }
    end

    binary_bytes = BSON::Binary.new("test", :generic).to_bson.to_s
    bench.report("Binary#from_bson ------>") do
      count.times { BSON::Binary.from_bson(BSON::ByteBuffer.new(binary_bytes)) }
    end

    code_bytes = BSON::Code.new("this.value = 1").to_bson.to_s
    bench.report("Code#from_bson -------->") do
      count.times { BSON::Code.from_bson(BSON::ByteBuffer.new(code_bytes)) }
    end

    decimal128_bytes = BSON::Decimal128.new(BigDecimal(123)).to_bson.to_s
    bench.report("Decimal128#from_bson -->") do
      count.times { BSON::Decimal128.from_bson(BSON::ByteBuffer.new(decimal128_bytes)) }
    end

    false_bytes = false.to_bson.to_s
    bench.report("Boolean#from_bson ----->") do
      count.times { BSON::Boolean.from_bson(BSON::ByteBuffer.new(false_bytes)) }
    end

    max_key_bytes = BSON::MaxKey.new.to_bson.to_s
    bench.report("MaxKey#from_bson ------>") do
      count.times { BSON::MaxKey.from_bson(BSON::ByteBuffer.new(max_key_bytes)) }
    end

    min_key_bytes = BSON::MinKey.new.to_bson.to_s
    bench.report("MinKey#from_bson ------>") do
      count.times { BSON::MinKey.from_bson(BSON::ByteBuffer.new(min_key_bytes)) }
    end

    object_id_bytes = BSON::ObjectId.new.to_bson.to_s
    bench.report("ObjectId#from_bson ---->") do
      count.times { BSON::ObjectId.from_bson(BSON::ByteBuffer.new(object_id_bytes)) }
    end

    regex_bytes = %r{\d+}.to_bson.to_s
    bench.report("Regexp#from_bson ------>") do
      count.times { Regexp.from_bson(BSON::ByteBuffer.new(regex_bytes)) }
    end

    string_bytes = "testing".to_bson.to_s
    bench.report("String#from_bson ------>") do
      count.times { String.from_bson(BSON::ByteBuffer.new(string_bytes)) }
    end

    symbol_bytes = "testing".to_bson.to_s
    bench.report("Symbol#from_bson ------>") do
      count.times { Symbol.from_bson(BSON::ByteBuffer.new(symbol_bytes)) }
    end

    time_bytes = Time.new.to_bson.to_s
    bench.report("Time#from_bson -------->") do
      count.times { Time.from_bson(BSON::ByteBuffer.new(time_bytes)) }
    end

    doc_bytes = document.to_bson.to_s
    bench.report("Document#from_bson ---->") do
      count.times { BSON::Document.from_bson(BSON::ByteBuffer.new(doc_bytes)) }
    end
  end
end

def benchmark_decimal128_from_string!
  test_helpers = Dir.glob(File.join(Dir.pwd, 'spec/support/common_driver.rb'))
  test_helpers.each { |t| require t }

  count = 100_000
  test_files =  Dir.glob(File.join(Dir.pwd, 'spec/support/driver-spec-tests/**/*.json'))
  tests = test_files.map { |file| BSON::CommonDriver::Spec.new(file) }

  tests[4].valid_tests.each do |test|
    puts test.string
    Benchmark.bm do |bench|
      bench.report("Decimal128#new from String ------>") do
        count.times { BSON::Decimal128.from_string(test.string) }
      end
    end
  end
end

def benchmark_decimal128_to_string!
  test_helpers = Dir.glob(File.join(Dir.pwd, 'spec/support/common_driver.rb'))
  test_helpers.each { |t| require t }

  count = 100_000
  test_files =  Dir.glob(File.join(Dir.pwd, 'spec/support/driver-spec-tests/**/*.json'))
  test_groups = test_files.map { |file| BSON::CommonDriver::Spec.new(file) }

  test_groups.each do |tests|
    tests.valid_tests.each do |test|
      decimal128 = BSON::Decimal128.from_string(test.string)
      puts decimal128.to_s
      Benchmark.bm do |bench|
        bench.report("Decimal128#to_string ------>") do
          count.times { BSON::Decimal128::Builder::ToString.new(decimal128).string }
        end
      end
    end
  end
end
