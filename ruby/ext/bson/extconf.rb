require "mkmf"
$CFLAGS << " -Wall -g -std=c99"
create_makefile("native")
