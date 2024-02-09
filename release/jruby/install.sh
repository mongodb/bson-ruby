#!/bin/bash

set -e

mkdir -p /rubies
cd /rubies

git clone https://github.com/rbenv/ruby-build.git
PREFIX=/usr ./ruby-build/install.sh

ruby-build -v jruby-9.3.13.0 /rubies/jruby
