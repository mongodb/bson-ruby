Review
======
obj.to_bson(encoded) appends bson for obj to encoded
string.to_bson_string(encoded) appends bson string to encoded
symbol.to_bson_cstring(encoded) appends bson cstring to encoded

unused
    Element
    Binary#bin_data

To Do
=====

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




