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
    ext.name = "NativeService"
    ext.ext_dir = "ext/bson"
    ext.lib_dir = "lib/bson"
  end
else
  require "rake/extensiontask"
  Rake::ExtensionTask.new do |ext|
    ext.name = "native"
    ext.ext_dir = "ext/bson"
    ext.lib_dir = "lib/bson"
  end
end

require "bson/version"

if RUBY_VERSION < "1.9"
  require "perf/bench"
else
  require_relative "perf/bench"
end

RSpec::Core::RakeTask.new(:spec)
RSpec::Core::RakeTask.new(:rspec)

task :build do
  system "gem build bson.gemspec"
end

task :release => :build do
  system "git tag -a v#{BSON::VERSION} -m 'Tagging release: #{BSON::VERSION}'"
  system "git push --tags"
  system "gem push bson-#{BSON::VERSION}.gem"
  system "rm bson-#{BSON::VERSION}.gem"
end

namespace :benchmark do

  task :ruby => :clean do
    puts "Benchmarking pure Ruby..."
    require "bson"
    benchmark!
  end

  task :native => :compile do
    puts "Benchmarking with native extensions..."
    require "bson"
    benchmark!
  end
end

task :default => [ :clean, :spec, :compile, :rspec ]
