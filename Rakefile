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

require "bundler"
Bundler.setup

$LOAD_PATH.unshift(File.expand_path("../lib", __FILE__))

require "rake"
require "rake/extensiontask"
require "rspec/core/rake_task"

def jruby?
  defined?(JRUBY_VERSION)
end

if jruby?
  require "rake/javaextensiontask"
  Rake::JavaExtensionTask.new do |ext|
    ext.name = "bson-ruby"
    ext.ext_dir = "src"
    ext.lib_dir = "lib"
  end
else
  require "rake/extensiontask"
  Rake::ExtensionTask.new do |ext|
    ext.name = "bson_native"
    ext.ext_dir = "ext/bson"
    ext.lib_dir = "lib"
  end
end

require "bson/version"

def extension
  RUBY_PLATFORM =~ /darwin/ ? "bundle" : "so"
end

require_relative "perf/bench"

RSpec::Core::RakeTask.new(:rspec)

if jruby?
  task :build => [ :clean_all, :compile ] do
    system "gem build bson.gemspec"
  end
else
  task :build => :clean_all do
    system "gem build bson.gemspec"
  end
end

task :clean_all => :clean do
  begin
    Dir.chdir(Pathname(__FILE__).dirname + "lib") do
      `rm bson_native.#{extension}`
      `rm bson_native.o`
      `rm bson-ruby.jar`
    end
  rescue Exception => e
    puts e.message
  end
end

task :spec => :compile do
  Rake::Task["rspec"].invoke
end

# Run bundle exec rake release with mri and jruby. Ex:
#
# rvm use 2.1.0@bson
# bundle exec rake release
# rvm use jruby@bson
# bundle exec rake release
task :release => :build do
  system "git tag -a v#{BSON::VERSION} -m 'Tagging release: #{BSON::VERSION}'"
  system "git push --tags"
  if jruby?
    system "gem push bson-#{BSON::VERSION}-java.gem"
    system "rm bson-#{BSON::VERSION}-java.gem"
  else
    system "gem push bson-#{BSON::VERSION}.gem"
    system "rm bson-#{BSON::VERSION}.gem"
  end
end

namespace :benchmark do

  task :ruby => :clean_all do
    puts "Benchmarking pure Ruby..."
    require "bson"
    benchmark!
  end

  task :native => :compile do
    puts "Benchmarking with native extensions..."
    require "bson"
    benchmark!
  end

  namespace :decimal128 do

    task :from_string do
      puts "Benchmarking creating Decimal128 objects from a string"
      require 'bson'
      benchmark_decimal128_from_string!
    end

    task :to_string do
      puts "Benchmarking getting a string representation of a Decimal128"
      require 'bson'
      benchmark_decimal128_to_string!
    end
  end
end

task :default => [ :clean_all, :spec ]
