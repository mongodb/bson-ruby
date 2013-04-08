BSON
====

Review
------
*.to_bson(encoded) appends bson for obj to encoded
string.to_bson_string(encoded) appends bson string to encoded
symbol.to_bson_cstring(encoded) appends bson cstring to encoded

unused
    Element
    Binary#bin_data

To Do
-----

consider array index map ~ gain: 0.42 (35 --> 21) Xeon

consider doc key memo
    no safey limit needed for non-pathological use (review this)
        symbol ~ gain: 0.25 (36 --> 27) Xeon
        string ~ gain: 0.15 (33 --> 28) Xeon
    with safety limit, mutex overhead eats up the benefit

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
