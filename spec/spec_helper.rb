# Copyright (C) 2009-2020 MongoDB Inc.
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

CURRENT_PATH = File.expand_path(File.dirname(__FILE__))
DRIVER_COMMON_BSON_TESTS = Dir.glob("#{CURRENT_PATH}/spec_tests/data/decimal128/*.json").sort
BSON_CORPUS_TESTS = Dir.glob("#{CURRENT_PATH}/spec_tests/data/corpus/*.json").sort
BSON_CORPUS_LEGACY_TESTS = Dir.glob("#{CURRENT_PATH}/spec_tests/data/corpus_legacy/*.json").sort

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "shared", "lib"))
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "ostruct"
require "bson"
require "json"
require "rspec"
require "yaml"

require 'support/spec_config'

if SpecConfig.instance.active_support?
  require "active_support/version"
  if ActiveSupport.version >= Gem::Version.new(7)
    # ActiveSupport wants us to require ALL of it all of the time.
    # See: https://github.com/rails/rails/issues/43851,
    # https://github.com/rails/rails/issues/43889, etc.
    require 'active_support'
  end
  require "active_support/time"
  require 'bson/active_support'
end

unless ENV['CI'] || BSON::Environment.jruby?
  begin
    require 'byebug'
  rescue Exception
  end
end

begin
  require 'mrss/lite_constraints'
rescue LoadError => exc
  raise LoadError.new <<~MSG.strip
    The test suite requires shared tooling to be installed.
      Please refer to spec/README.md for instructions.
    #{exc.class}: #{exc}
  MSG
end

Dir["./spec/support/**/*.rb"].each { |file| require file }

# Alternate IO class that returns a String from #readbyte.
# See RUBY-898 for more information on why we need to test this.
# Ruby core documentation says IO#readbyte returns a Fixnum, but
# OpenSSL::SSL::SSLSocket#readbyte returns a String.
class AlternateIO < StringIO

  # Read a byte from the stream.
  #
  # @returns [ String ] A String representation of the next byte.
  def readbyte
    super.chr
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end

  # To ensure that calling GC.compact does not produce unexpected behavior,
  # randomly call GC.compact after a small percentage of tests in the suite.
  # This behavior is only enabled when the COMPACT environment variable is true.
  if SpecConfig.instance.compact?
    config.after do
      if rand < SpecConfig::COMPACTION_CHANCE
        GC.compact
      end
    end
  end

  config.extend Mrss::LiteConstraints
end
