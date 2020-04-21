require "mkmf"
$CFLAGS << " -Wall -g -std=c99"
RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] if ENV['CC']
create_makefile("bson_native")
