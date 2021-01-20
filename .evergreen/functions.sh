set_home() {
  if test -z "$HOME"; then
    export HOME=$(pwd)
  fi
}

set_env_vars() {
  export CI=evergreen

  # JRUBY_OPTS were initially set for Mongoid
  export JRUBY_OPTS="--server -J-Xms512m -J-Xmx2G"

  if test "$BSON" = min; then
    export BUNDLE_GEMFILE=gemfiles/bson_min.gemfile
  elif test "$BSON" = master; then
    export BUNDLE_GEMFILE=gemfiles/bson_master.gemfile
  fi
}

bundle_install() {
  #which bundle
  #bundle --version
  args=--quiet
  if test -n "$BUNDLE_GEMFILE"; then
    args="$args --gemfile=$BUNDLE_GEMFILE"
  fi
  echo "Running bundle install $args"
  bundle install $args
}

install_deps() {
  bundle_install
  bundle exec rake clean
}

kill_jruby() {
  jruby_running=`ps -ef | grep 'jruby' | grep -v grep | awk '{print $2}'`
  if [ -n "$jruby_running" ];then
    echo "terminating remaining jruby processes"
    for pid in $(ps -ef | grep "jruby" | grep -v grep | awk '{print $2}'); do kill -9 $pid; done
  fi
}
