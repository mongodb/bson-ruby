BSON
====

Review
------
PACK specify little-ending - 'l<' 'q<'
TIMESTAMP_PACK

Optimizations
-------------
append to encoded
    *.to_bson(encoded) appends bson for obj to encoded
    string.to_bson_string(encoded) appends bson string to encoded
    symbol.to_bson_cstring(encoded) appends bson cstring to encoded
array index map ~ 0.38 (32 --> 20) Xeon
Encodable to_bson_int32
    encode_string_with_placeholder ~ gain: 0.15 (36 --> 31) Core 2
    encode_bson_with_placeholder ~ gain: 0.07 (37 --> 35) Core 2
    encode_binary_data_with_placeholder

Unused
------
Element
Binary#bin_data

Ruby prof for encoding of twitter data looks good
    training/data/sampledata/sampledata/twitter.json is from the training files (private repo)

To Do
-----
consider refactoring
    encode_with_placeholder(adjust = 0, encoded = ''.force_encoding(BINARY))
        adjust = 0 : encode_bson_with_placeholder
        adjust = 4 : encode_string_with_placeholder
        adjust = 5 : encode_binary_data_with_placeholder

consider doc key memo
    note threading concerns
    no safey limit needed for non-pathological use (review this)
        symbol ~ gain: 0.25 (36 --> 27) Xeon
        string ~ gain: 0.15 (33 --> 28) Xeon
    with safety limit, mutex overhead eats up the benefit

consider BSON::Integer#to_bson* - native !?!
    BSON::Integer#bson_int64?
    BSON::Integer#bson_int32?

consider append for
    to_bson_time - has native
    to_bson_int32 - has native
    to_bson_int64 - has native

optimize/examine

    Mongo::Protocol
        Insert
        Message

Notes
-----

modules and classes have some overhead that can be significant
