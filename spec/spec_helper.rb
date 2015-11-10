# Copyright (C) 2009-2014 MongoDB Inc.
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

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "bson"
require "json"
require "rspec"
require "yaml"

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
