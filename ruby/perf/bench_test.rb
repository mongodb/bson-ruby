$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'bson'
require 'json'
require 'stringio'
require 'test/unit'
require 'benchmark'
require 'ruby-prof'

class BenchTest < Test::Unit::TestCase

  def setup
    puts
    @count = 10_000
    @label_width = 30
  end

  def teardown
    puts
  end

  def gc_allocated
    gc_stat = []
    GC.start
    gc_stat << GC.stat
    yield
    GC.start
    gc_stat << GC.stat
    gc_stat[1][:total_allocated_object] - gc_stat[0][:total_allocated_object]
  end

  def print_gain_and_freed_objects(measurement, gc_stat, i)
    h = Hash[*[:label, :utime, :stime, :cutime, :cstime, :real].zip(measurement[i].to_a).flatten]
    h[:allocated] = gc_stat[i+1][:total_allocated_object] - gc_stat[i][:total_allocated_object]
    h[:freed] = gc_stat[i+1][:total_freed_object] - gc_stat[i][:total_freed_object]
    h[:base] = measurement[0].utime if i > 0
    h[:gain] = 1.0 - h[:utime]/h[:base] if i > 0
    [
        [ "label: \"%s\"", :label ],
        [ ", allocated: %d", :allocated ],
        [ ", freed: %d", :freed ],
        [ ", user: %.1f", :utime ],
        [ ", base: %.1f", :base ],
        [ ", gain: %.2f", :gain ]
    ].each do |format, key|
      print (format % h[key]) if h[key]
    end
    puts
  end

  def benchmark_with_gc(count, method_label_pairs)
    measurement = []
    gc_stat = []
    GC.start
    gc_stat << GC.stat
    method_label_pairs.each_with_index do |method_label_pair, i|
      meth, label = method_label_pair
      meth.call
      measurement << Benchmark.measure(label) do
        count.times.each_with_index {|j| yield j }
      end
      GC.start
      gc_stat << GC.stat
      print_gain_and_freed_objects(measurement, gc_stat, i)
    end
    method_label_pairs.first.first.call
  end

  # Optimization committed --------------------------------------------------------------------------------------------

  def reset_old_array_index
    Array.class_eval <<-EVAL
      def to_bson(encoded = ''.force_encoding(BSON::BINARY))
        encode_with_placeholder_and_null(BSON_ADJUST, encoded) do |encoded|
          each_with_index do |value, index|
            encoded << value.bson_type
            index.to_s.to_bson_cstring(encoded)
            value.to_bson(encoded)
          end
        end
      end
    EVAL
  end

  def set_new_array_index_optimize
    Array.class_eval <<-EVAL
        @@_BSON_INDEX_SIZE = 1024
        @@_BSON_INDEX_ARRAY = ::Array.new(@@_BSON_INDEX_SIZE){|i| (i.to_s.force_encoding(BSON::BINARY) << BSON::NULL_BYTE).freeze}.freeze
        def to_bson(encoded = ''.force_encoding(BSON::BINARY))
          encode_with_placeholder_and_null(BSON_ADJUST, encoded) do |encoded|
            each_with_index do |value, index|
              encoded << value.bson_type
              if index < @@_BSON_INDEX_SIZE
                encoded << @@_BSON_INDEX_ARRAY[index]
              else
                index.to_s.to_bson_cstring(encoded)
              end
              value.to_bson(encoded)
            end
          end
        end
    EVAL
  end

  def test_array_index_optimization
    size = 1024
    array = Array.new(size){|i| i}
    method_label_pairs = [
      [ method(:reset_old_array_index), 'Array index optimize none'],
      [ method(:set_new_array_index_optimize), 'Array index optimize 1024'] # Xeon user: 20.3, base: 33.2, gain: 0.39
    ]
    benchmark_with_gc(@count, method_label_pairs) { array.to_bson }
  end

  def reset_old_encode_bson_with_placeholder
    BSON::Encodable.module_eval <<-EVAL
      def encode_with_placeholder_and_null(adjust, encoded = ''.force_encoding(BSON::BINARY))
        pos = encoded.bytesize
        encoded << PLACEHOLDER
        yield(encoded)
        encoded << BSON::NULL_BYTE
        encoded[pos, 4] = (encoded.bytesize - pos + adjust).to_bson
        encoded
      end
    EVAL
  end

  def set_new_encode_bson_with_placeholder_v0
    BSON::Encodable.module_eval <<-EVAL
      def encode_with_placeholder_and_null(adjust, encoded = ''.force_encoding(BINARY))
        pos = encoded.bytesize
        encoded << PLACEHOLDER
        yield(encoded)
        encoded << BSON::NULL_BYTE
        encoded[pos, 4] = (encoded.bytesize - pos + adjust).to_bson_int32('') # [ encoded.bytesize - pos ].pack('l<') #
        encoded
      end
    EVAL
  end

  def set_new_encode_bson_with_placeholder_v1
    BSON::Encodable.module_eval <<-EVAL
      def encode_with_placeholder_and_null(adjust, encoded = ''.force_encoding(BINARY))
        pos = encoded.bytesize
        encoded << PLACEHOLDER
        yield(encoded)
        encoded << BSON::NULL_BYTE
        encoded.setint32(pos, encoded.bytesize - pos + adjust) # [ encoded.bytesize - pos ].pack('l<') #
        encoded
      end
    EVAL
  end

  def test_encode_bson_with_placeholder
    size = 1
    hash = Hash[*(0..size).to_a.collect{|i| [ ('a' + i.to_s), i.to_s]}.flatten]
    @count = 2_000_000
    method_label_pairs = [
        [ method(:reset_old_encode_bson_with_placeholder), 'Encode bson optimize to_bson'],
        [ method(:set_new_encode_bson_with_placeholder_v0), 'Encode bson optimize to_bson_int32'], # user: 22.2, base: 28.5, gain: 0.22
        [ method(:set_new_encode_bson_with_placeholder_v1), 'Encode bson optimize setint32']       # user: 22.2, base: 28.5, gain: 0.22
    ]
    benchmark_with_gc(@count, method_label_pairs) { hash.to_bson }
  end

  def reset_old_encode_string_with_placeholder
    BSON::Encodable.module_eval <<-EVAL
      def encode_with_placeholder_and_null(adjust, encoded = ''.force_encoding(BSON::BINARY))
        pos = encoded.bytesize
        encoded << PLACEHOLDER
        yield(encoded)
        encoded << BSON::NULL_BYTE
        encoded[pos, 4] = (encoded.bytesize - pos + adjust).to_bson
        encoded
      end
    EVAL
  end

  def set_new_encode_string_with_placeholder_v0
    BSON::Encodable.module_eval <<-EVAL
      def encode_with_placeholder_and_null(adjust, encoded = ''.force_encoding(BINARY))
        pos = encoded.bytesize
        encoded << PLACEHOLDER
        yield(encoded)
        encoded << BSON::NULL_BYTE
        encoded[pos, 4] = (encoded.bytesize - pos + adjust).to_bson_int32('') # [ encoded.bytesize - pos - 4 ].pack('l<') #
        encoded
      end
    EVAL
  end

  def set_new_encode_string_with_placeholder_v1
    BSON::Encodable.module_eval <<-EVAL
      def encode_with_placeholder_and_null(adjust, encoded = ''.force_encoding(BINARY))
        pos = encoded.bytesize
        encoded << PLACEHOLDER
        yield(encoded)
        encoded << BSON::NULL_BYTE
        encoded.setint32(pos, encoded.bytesize - pos + adjust) # [ encoded.bytesize - pos - 4 ].pack('l<') #
        encoded
      end
    EVAL
  end

  def test_encode_string_with_placeholder
    size = 1
    hash = Hash[*(0..size).to_a.collect{|i| [ ('a' + i.to_s), i.to_s]}.flatten]
    @count = 2_000_000
    method_label_pairs = [
        [ method(:reset_old_encode_string_with_placeholder), 'Encode string optimize to_bson'],
        [ method(:set_new_encode_string_with_placeholder_v0), 'Encode string optimize to_bson_int32'], # Xeon user: 22.2, base: 27.7, gain: 0.20
        [ method(:set_new_encode_string_with_placeholder_v1), 'Encode string optimize setint32']       # Xeon user: 22.2, base: 27.7, gain: 0.20
    ]
    benchmark_with_gc(@count, method_label_pairs) { hash.to_bson }
  end

  def reset_old_integer_to_bson
    Integer.class_eval <<-EVAL
      def to_bson(encoded = ''.force_encoding(BINARY))
        unless bson_int64?
          out_of_range!
        else
          bson_int32? ? to_bson_int32(encoded) : to_bson_int64(encoded)
        end
      end
    EVAL
  end

  def set_new_integer_to_bson
    Integer.class_eval <<-EVAL
      def to_bson(encoded = ''.force_encoding(BINARY))
        if bson_int32?
          to_bson_int32(encoded)
        elsif bson_int64?
          to_bson_int64(encoded)
        else
          out_of_range!
        end
      end
    EVAL
  end

  def test_integer_to_bson_optimization
    size = 1024
    hash = Hash[*(0..size).to_a.collect{|i| [ ('a' + i.to_s).to_sym, i]}.flatten]
    method_label_pairs = [
      [ method(:reset_old_integer_to_bson), 'Integer to_bson optimize none'],
      [ method(:set_new_integer_to_bson), 'Integer to_bson optimize test order']
    ]
    benchmark_with_gc(@count, method_label_pairs) { hash.to_bson }
  end

  # Optimization NOT committed ----------------------------------------------------------------------------------------

  def reset_old_hash_to_bson
    Hash.class_eval <<-EVAL
      def to_bson(encoded = ''.force_encoding(BSON::BINARY))
        encode_with_placeholder_and_null(BSON_ADJUST, encoded) do |encoded|
          each do |field, value|
            encoded << value.bson_type
            field.to_bson_cstring(encoded)
            value.to_bson(encoded)
          end
        end
      end
    EVAL
  end

  def set_new_hash_to_bson_v0
    # if-else seems to work better than setting a variable to method
    # pending - mutex
    Hash.class_eval <<-EVAL
      @@_memo_threshold = 65535
      @@_memo_hash = Hash.new
      @@_memo_mutex = Mutex.new
      def _memo_set(field)
        @@_memo_mutex.synchronize do
          @@_memo_hash[field] = @@_memo_hash.fetch(field) { yield }
        end
      end
      def _memo_fetch(field)
        @@_memo_mutex.synchronize do
          @@_memo_hash.fetch(field) { yield }
        end
      end
      def to_bson(encoded = ''.force_encoding(BSON::BINARY))
        if size < @@_memo_threshold
          encode_with_placeholder_and_null(BSON_ADJUST, encoded) do |encoded|
            each do |field, value|
              encoded << value.bson_type
              encoded << _memo_set(field) { field.to_bson_cstring }
              value.to_bson(encoded)
            end
          end
        else
          encode_with_placeholder_and_null(BSON_ADJUST, encoded) do |encoded|
            each do |field, value|
              encoded << value.bson_type
              encoded << _memo_fetch(field) { field.to_bson_cstring }
              value.to_bson(encoded)
            end
          end
        end
      end
    EVAL
  end

  def set_new_hash_to_bson_v1
    Hash.class_eval <<-EVAL
        @@_memo_hash = Hash.new
        def _memo(field)
          @@_memo_hash[field] = @@_memo_hash.fetch(field) { yield }
        end
        def to_bson(encoded = ''.force_encoding(BSON::BINARY))
          encode_with_placeholder_and_null(BSON_ADJUST, encoded) do |encoded|
            each do |field, value|
              encoded << value.bson_type
              encoded << _memo(field) { field.to_bson_cstring }
              value.to_bson(encoded)
            end
          end
        end
    EVAL
  end

  def test_symbol_key_optimization
    size = 1024
    hash = Hash[*(0..size).to_a.collect{|i| [ ('a' + i.to_s).to_sym, i]}.flatten]
    method_label_pairs = [
      [ method(:reset_old_hash_to_bson), 'Symbol key optimize none'],
      [ method(:set_new_hash_to_bson_v0), 'Symbol key optimize hash key v0'], # Xeon user: 33.4, base: 35.9, gain: 0.07
      [ method(:set_new_hash_to_bson_v1), 'Symbol key optimize hash key v1']  # Xeon user: 26.4, base: 35.9, gain: 0.26
    ]
    benchmark_with_gc(@count, method_label_pairs) { hash.to_bson }
  end

  def test_string_key_optimization
    size = 1024
    hash = Hash[*(0..size).to_a.collect{|i| [ ('a' + i.to_s), i]}.flatten]
    method_label_pairs = [
        [ method(:reset_old_hash_to_bson), 'Symbol key optimize none'],
        [ method(:set_new_hash_to_bson_v0), 'Symbol key optimize hash key v0'], # Xeon user: 34.5, base: 32.6, gain: -0.06
        [ method(:set_new_hash_to_bson_v1), 'Symbol key optimize hash key v1'] # Xeon user: 27.5, base: 32.6, gain: 0.15
    ]
    benchmark_with_gc(@count, method_label_pairs) { hash.to_bson }
  end

  # Discarded as not worthy -------------------------------------------------------------------------------------------

  def reset_old_hash_from_bson
    BSON::Hash.class_eval <<-EVAL
      def from_bson(bson)
        hash = new
        bson.read(4) # Swallow the first four bytes.
        while (type = bson.readbyte.chr) != NULL_BYTE
          field = bson.gets(NULL_BYTE).from_bson_string.chop!
          hash[field] = BSON::Registry.get(type).from_bson(bson)
        end
        hash
      end
    EVAL
  end

  def set_new_hash_from_bson
    BSON::Hash.class_eval <<-EVAL
      def from_bson(bson)
        hash = new
        bson.seek(4, IO::SEEK_CUR) # Swallow the first four bytes.
        while (type = bson.readbyte.chr) != NULL_BYTE
          field = bson.gets(NULL_BYTE).from_bson_string.chop!
          hash[field] = BSON::Registry.get(type).from_bson(bson)
        end
        hash
      end
    EVAL
  end

  def test_seek
    size = 1
    hash = Hash[*(0..size).to_a.collect{|i| [ ('a' + i.to_s), i.to_s]}.flatten]
    @count = 2_000_000
    method_label_pairs = [
        [ method(:reset_old_hash_from_bson), 'Encode bson optimize none'],
        [ method(:set_new_hash_from_bson), 'Encode bson optimize seek'] # Xeon user: 28.2, base: 28.3, gain: 0.00
    ]
    benchmark_with_gc(@count, method_label_pairs) { hash.to_bson }
  end

  def reset_integer_bson_int32?
    Integer.class_eval <<-EVAL
      def bson_int32?
        (MIN_32BIT <= self) && (self <= MAX_32BIT)
      end
    EVAL
  end

  def set_new_integer_bson_int32?
    Integer.class_eval <<-EVAL
      @@FIXNUM_HIGHBITS32 = (-1 << 32)
      def bson_int32?
        (self & @@FIXNUM_HIGHBITS32) == 0
      end
    EVAL
  end

  def test_bson_int32?
    count = 100_000_000
    method_label_pairs = [
        [ method(:reset_integer_bson_int32?), 'Integer#bson_int32? old'],
        [ method(:set_new_integer_bson_int32?), 'Integer#bson_int32? new'] # user: 34.9, base: 21.4, gain: -0.63
    ]
    benchmark_with_gc(count, method_label_pairs) {|i| i.bson_int32? }
  end

  # Ruby-prof profiling -----------------------------------------------------------------------------------------------

  def doc_stats(tally, obj)
    tally[obj.class.name] += 1
    case obj.class.name
      when 'Array'; obj.each {|elem| doc_stats(tally, elem) }
      when 'FalseClass'; return
      when 'Fixnum'; return
      when 'Float'; return
      when 'Hash'; obj.each {|elem| doc_stats(tally, elem) }
      when 'NilClass'; return
      when 'String'; return
      when 'TrueClass'; return
      else p obj.class; exit
    end
  end

  def test_doc_stats
    json_filename = '../../../training/data/sampledata/twitter.json'
    line_limit = 10_000
    twitter = nil
    File.open(json_filename, 'r') do |f|
      twitter = line_limit.times.collect { JSON.parse(f.gets) }
    end
    tally = Hash.new(0)
    doc_stats(tally, twitter)
    tally = tally.to_a.sort{|a,b| b[1] <=> a[1]}
    pp tally
    obj_count = tally.inject(0){|sum, elem| sum + elem[1]}
    puts "objects: #{obj_count}"
    puts "objects/doc: #{obj_count/line_limit}"
  end

  def test_encode_ruby_prof
    json_filename = '../../../training/data/sampledata/twitter.json'
    line_limit = 10_000
    twitter = nil
    File.open(json_filename, 'r') do |f|
      twitter = line_limit.times.collect { JSON.parse(f.gets) }
    end


    profile = nil
    allocated = nil
    Benchmark.bm(@label_width) do |bench|
      bench.report('test encode ruby prof') do

        allocated = gc_allocated do
          RubyProf.start
          twitter.each {|doc| doc.to_bson }
          profile = RubyProf.stop
        end

      end
    end
    puts "allocated: #{allocated} allocated/line: #{allocated/line_limit}"

    File.open('encode-ruby-prof.out', 'w') do |f|
      RubyProf::FlatPrinter.new(profile).print(f)
      RubyProf::GraphPrinter.new(profile).print(f, {})
    end
  end

  def test_decode_ruby_prof
    json_filename = '../../../training/data/sampledata/twitter.json'
    line_limit = 10_000
    twitter = nil
    File.open(json_filename, 'r') do |f|
      twitter = line_limit.times.collect { StringIO.new(JSON.parse(f.gets).to_bson) }
    end

    profile = nil
    allocated = nil
    Benchmark.bm(@label_width) do |bench|
      bench.report('test decode ruby prof') do

        allocated = gc_allocated do
          RubyProf.start
          twitter.each {|io| io.rewind; Hash.from_bson(io) }
          profile = RubyProf.stop
        end

      end
    end
    puts "allocated: #{allocated} allocated/line: #{allocated/line_limit}"

    File.open('decode-ruby-prof.out', 'w') do |f|
      RubyProf::FlatPrinter.new(profile).print(f)
      RubyProf::GraphPrinter.new(profile).print(f, {})
    end
  end

end

