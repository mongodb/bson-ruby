BSON
====

Review
------
obj.to_bson(encoded) appends bson for obj to encoded
string.to_bson_string(encoded) appends bson string to encoded
symbol.to_bson_cstring(encoded) appends bson cstring to encoded

unused
    Element
    Binary#bin_data

To Do
-----

consider array index map ~ 46% gain (41 -> 22)

consider symbol to bson string map ~ 34% gain (61 -> 40)
    no safey limit needed for non-pathological use (review this)

consider string keys to bson string map with safety limit ~ 29% gain (157 -> 112)

consider append for

    to_bson_time - has native
    to_bson_int32 - has native
    to_bson_int64 - has native

optimize/examine

    Array#to_bson index.to_s in pure Ruby
        e.g., const array of strings for first 1024
    Mongo::Protocol
        Insert
        Message
