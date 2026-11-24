# frozen_string_literal: true
# rubocop:disable all

require 'mkmf'

append_cflags(["-Wall", "-g", "-std=c99"])

have_func('rb_enc_interned_str', 'ruby/encoding.h')

create_makefile('bson_native')
