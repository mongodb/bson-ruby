#!/bin/bash

set -e

mkdir -p /rubies
cd /rubies

git clone https://github.com/rbenv/ruby-build.git
PREFIX=/usr ./ruby-build/install.sh

ruby-build -v jruby-9.2.11.1 /rubies/jruby
