#!/bin/bash

set -o xtrace   # Write all commands first to stderr
set -o errexit  # Exit the script with error if any of the commands fail

# Supported/used environment variables:
#       RVM_RUBY      Define the Ruby version to test with, using its RVM identifier.
#                     For example: "ruby-2.4" or "jruby-9.2"

. `dirname "$0"`/../spec/shared/shlib/distro.sh
. `dirname "$0"`/../spec/shared/shlib/set_env.sh
. `dirname "$0"`/functions.sh

set_env_vars

set_env_ruby

install_deps

echo "Running tests"
if test -n "$TEST_CMD"; then
  eval $TEST_CMD
else
  bundle exec rake spec
fi

test_status=$?
echo "TEST STATUS"
echo ${test_status}

kill_jruby

exit ${test_status}
