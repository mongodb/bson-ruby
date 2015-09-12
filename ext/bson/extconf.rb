require "mkmf"
$CFLAGS << " -Wall -g -std=c99"

HEADER_DIRS = [ '/usr/local/include/libbson-1.0' ]
LIB_DIRS = [ '/usr/local/lib' ]

dir_config('bson', HEADER_DIRS, LIB_DIRS)
create_makefile("native")
