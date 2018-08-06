#!/bin/bash

set -o xtrace   # Write all commands first to stderr
set -o errexit  # Exit the script with error if any of the commands fail

# Supported/used environment variables:
#       RVM_RUBY      Define the Ruby version to test with, using its RVM identifier.
#                     For example: "ruby-2.3" or "jruby-9.1"

RVM_RUBY=${RVM_RUBY:-}

# Necessary for jruby
export JAVACMD=/opt/java/jdk8/bin/java
export PATH=$PATH:/opt/java/jdk8/bin

if [ "$RVM_RUBY" == "ruby-head" ]; then
  # 12.04, 14.04 and 16.04 are good
  wget -O ruby-head.tar.bz2 http://rubies.travis-ci.org/ubuntu/`lsb_release -rs`/x86_64/ruby-head.tar.bz2
  tar xf ruby-head.tar.bz2
  export PATH=`pwd`/ruby-head/bin:`pwd`/ruby-head/lib/ruby/gems/2.6.0/bin:$PATH
  ruby --version
  ruby --version |grep dev
  
  # With rvm we reinstall ruby-head every run: rvm reinstall $RVM_RUBY
else
  . ~/.rvm/scripts/rvm

  # Don't errexit because this may call scripts which error
  set +o errexit
  rvm use $RVM_RUBY
  set -o errexit

  # Ensure we're using the right ruby
  python - <<EOH
ruby = "${RVM_RUBY}".split("-")[0]
version = "${RVM_RUBY}".split("-")[1]
assert(ruby in "`ruby --version`")
assert(version in "`ruby --version`")
EOH

  echo 'updating rubygems'
  gem update --system

  # ruby-head comes with bundler and gem complains
  # because installing bundler would overwrite the bundler binary
  gem install bundler
fi

echo "Installing all gem dependencies"
bundle install
bundle exec rake clean

echo "Running specs"
bundle exec rake spec
test_status=$?
echo "TEST STATUS"
echo ${test_status}

jruby_running=`ps -ef | grep 'jruby' | grep -v grep | awk '{print $2}'`
if [ -n "$jruby_running" ];then
  echo "terminating remaining jruby processes"
  for pid in $(ps -ef | grep "jruby" | grep -v grep | awk '{print $2}'); do kill -9 $pid; done
fi

exit ${test_status}
