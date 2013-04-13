require "bundler"
Bundler.setup

$LOAD_PATH.unshift(File.expand_path("../lib", __FILE__))

require "rake"
require "rspec/core/rake_task"

require "bson/version"

if RUBY_VERSION < "1.9"
  require "perf/bench"
else
  require_relative "perf/bench"
end

RSpec::Core::RakeTask.new(:spec)
RSpec::Core::RakeTask.new(:rspec)

Cucumber::Rake::Task.new do |t|
  t.cucumber_opts = %w{--format pretty}
end

def extension
  RUBY_PLATFORM =~ /darwin/ ? "bundle" : "so"
end

def compile!
  puts "Compiling native extensions..."
  Dir.chdir(Pathname(__FILE__).dirname + "ext/bson") do
    `bundle exec ruby extconf.rb`
    `make`
    `cp native.#{extension} ../../lib/bson`
  end
end

task :build do
  system "gem build bson.gemspec"
end

task :compile do
  compile!
end

task :clean do
  puts "Cleaning out native extensions..."
  begin
    Dir.chdir(Pathname(__FILE__).dirname + "lib/bson") do
      `rm native.#{extension}`
      `rm native.o`
    end
  rescue Exception => e
    puts e.message
  end
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

  task :c => :compile do
    puts "Benchmarking with C extensions..."
    require "bson"
    benchmark!
  end
end

task :default => [ :clean, :spec, :compile, :rspec ]
