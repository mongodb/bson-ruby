#!/bin/bash

set -e

mkdir -p /rubies
cd /rubies

git clone https://github.com/rbenv/ruby-build.git
PREFIX=/usr ./ruby-build/install.sh

# JRuby 9.3.9.0 is the most recent version that uses
# JOpenSSL 0.12.2. More recent versions use JOpenSSL 0.14.2,
# which appears to be unable to build signed gems.
# See: https://github.com/jruby/jruby-openssl/issues/292
ruby-build -v jruby-9.3.9.0 /rubies/jruby
