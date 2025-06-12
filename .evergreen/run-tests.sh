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

# TODO: move this to shared/shlib/set_env.sh
export JAVA_HOME="/opt/java/jdk21"
export SOURCE_VERSION=21
export TARGET_VERSION=21
# END TODO
echo "Running specs"
bundle exec rake spec
test_status=$?
echo "TEST STATUS"
echo ${test_status}

kill_jruby

exit ${test_status}
