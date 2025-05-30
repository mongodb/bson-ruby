# frozen_string_literal: true
# rubocop:disable all

require 'mkmf'

append_cflags(["-Wall", "-g", "-std=c99"])

create_makefile('bson_native')
