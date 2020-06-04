#!/bin/bash

set -e

export PATH=/rubies/jruby/bin:$PATH

gem install bundler --no-document
rm -f *.lock
rm -f *.gem
bundle install --without=test
rake build
/app/release/verify-signature.sh *.gem
