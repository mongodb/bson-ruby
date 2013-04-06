Review
======
obj.to_bson(encoded) now appends bson for obj to encoded
Element unused

To Do
=====
String#to_bson optimization with placeholder
consider append for
    to_bson_string # character encoding concerns
    to_bson_cstring # character encoding concerns

    to_bson_time
    to_bson_int32 - has native
    to_bson_int64 - has native

optimize
    Array#to_bson index.to_s in pure Ruby
        e.g., const array of strings for first 1024
    Mongo::Protocol::Message




