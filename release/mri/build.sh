#!/bin/bash

set -e

rm -f *.lock
rm -f *.gem
bundle install --without=test
rake build
/app/release/verify-signature.sh *.gem
