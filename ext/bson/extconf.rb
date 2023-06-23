require 'mkmf'

$CFLAGS << ' -Wall -g -std=c99'
have_func 'arc4random'

create_makefile('bson_native')
