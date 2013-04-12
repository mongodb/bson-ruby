BSON [![Build Status](https://secure.travis-ci.org/mongodb/bson-ruby.png?branch=master&.png)](http://travis-ci.org/mongodb/bson-ruby) [![Code Climate](https://codeclimate.com/github/mongodb/bson-ruby.png)](https://codeclimate.com/github/mongodb/bson-ruby)
====

Review
------

* Unused
** Binary#bin_data

Optimizations committed
-----------------------

* append to encoded
** \*.to_bson(encoded) appends bson for obj to encoded
** string.to_bson_string(encoded) appends bson string to encoded
** symbol.to_bson_cstring(encoded) appends bson cstring to encoded
* array index map ~ Xeon user: 20.1, base: 33.0, gain: 0.39
* Encodable optimization
** plus native append for
*** BSON::Integer#to_bson_int32
*** BSON::Integer#to_bson_int64
*** BSON::Integer#to_bson_time
*** BSON::String#setint32
** test_encode_bson_with_placeholder - Core 2
*** ruby to_bson,       freed: 44000078, user: 32.8
*** ruby to_bson_int32, freed: 32000118, user: 26.9, base: 32.8, gain: 0.18
*** ruby setint32,      freed: 26000119, user: 25.0, base: 32.8, gain: 0.24
*** ext  to_bson,       freed: 32000078, user: 29.5
*** ext  to_bson_int32, freed: 20000118, user: 22.4, base: 29.5, gain: 0.24
*** ext  setint32,      freed: 14000119, user: 18.6, base: 29.5, gain: 0.37
** test_encode_string_with_placeholder - Core 2
*** ruby to_bson,       freed: 42873246, user: 31.6
*** ruby to_bson_int32, freed: 31999713, user: 25.9, base: 31.6, gain: 0.18
*** ruby setint32,      freed: 26000120, user: 24.6, base: 31.6, gain: 0.22
*** ext  to_bson,       freed: 32000078, user: 29.5
*** ext  to_bson_int32, freed: 20000118, user: 22.1, base: 29.5, gain: 0.25
*** ext  setint32,      freed: 14000119, user: 18.4, base: 29.5, gain: 0.38
* integer.to_bson test order - test bson_int32? first as most numbers fit
** ruby bson_int64?     allocated: 71780058, freed: 71780043, user: 41.4
** ruby bson_int32?     allocated: 51280097, freed: 51280093, user: 35.4, base: 41.4, gain: 0.14

Allocations
-----------

* twitter
** documents   10000
** objects/doc   185
** objects   1852053
*** String    811731
*** Array     646586
*** NilClass  120515
*** Fixnum    120181
*** FalseClass 89655
*** Hash       44144
*** TrueClass  18245
*** Float        996
** encode - allocated: 2697231 allocated/doc: 248
** decode - allocated: 3080522 allocated/doc: 308

To Do - Review
--------------

* getint32 - bson.read(4).unpack(Int32::PACK)
** probably minimal but still worth refactoring - 7 occurrences
* consider doc key memo
** note threading concerns
** no safety limit needed for non-pathological use (review this)
*** symbol ~ gain: 0.25 (36 --> 27) Xeon, gain: 0.34 (41 --> 27) Core 2
*** string ~ gain: 0.15 (33 --> 28) Xeon, gain: 0.24 (39 --> 29) Core 2
** with safety limit, mutex overhead eats up the benefit on Xeon
*** symbol ~ gain: 0.15 (41 --> 35) Core 2
*** string ~ gain: 0.05 (39 --> 37) Core 2
* check_for_illegal_characters - other illegals like '.' and '$'
** optimize - anywhere not needed?

* consider native
** BSON::Integer#bson_int32?
** BSON::Integer#to_bson
** BSON::Integer#bson_int64?

* optimize/examine
** Mongo::Protocol
*** Insert
*** Message

Minimal? - Review
-----------------


Discarded
---------

* seek instead of read for swallow / throw away - StringIO#seek(4, IO::SEEK_CUR) - garbage same
** Array#from_bson
** Hash@from_bson
* bson_int32? - via Ruby bit ops

Notes
-----

* Ruby prof for encoding of twitter data looks good
** training/data/sampledata/sampledata/twitter.json is from the training files (private repo)
* modules and classes have some overhead that can be significant
* optimization in Ruby seems to have more effect for Core 2 and less for Xeon
