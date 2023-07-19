# frozen_string_literal: true
# rubocop:disable all

require 'mkmf'

$CFLAGS << ' -Wall -g -std=c99'
have_library 'bsd'
have_func 'arc4random'

create_makefile('bson_native')
