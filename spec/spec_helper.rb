$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

if ENV["CI"]
  require "simplecov"
  require "coveralls"
  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  SimpleCov.start do
    add_filter "spec"
  end
end

require "bson"
require "rspec"
require "yaml"

Dir["./spec/support/**/*.rb"].each { |file| require file }
