Performance Notes
=================

Pending
-------

- codepoints and getbyte, setbyte, << for BSON_TYPE
- string.force_encoding("UTF-8").valid_encoding?

Top concerns
------------

- String - pure - cext@ - Tyler has experience, says UTF8 (with LATIN1 subset) is sufficient, note keys need special char check
  - to_utf8_binary@
  - to_bson_string@
  - to_bson_cstring@
  - append_bson_int32
  - to_bson_key - rb_string_to_bson_key
  - check_for_illegal_characters
  - encode
  - set_int32
  - force_encoding
  - to_bson
- Symbol
  - to_bson
  - to_bson_key
  - rb_symbol_to_bson_key
- Binary
  - rb_binary_to_bson
- Integer - sizing done twice for serialization - bson_type and to_bson
  - discarded as not worthy
    - new_hash_to_bson_hint
    - new_hash_to_bson_integer
  - Array to_bson - repeat above

TODO: Review
------------

- key optimization
  - note threading concerns
  - no safety limit needed for non-pathological use (review this)
  - symbol ~ gain: 0.25 (36 --> 27) Xeon, gain: 0.34 (41 --> 27) Core 2
  - string ~ gain: 0.15 (33 --> 28) Xeon, gain: 0.24 (39 --> 29) Core 2
  - with safety limit, mutex overhead eats up the benefit on Xeon
  - symbol ~ gain: 0.15 (41 --> 35) Core 2
  - string ~ gain: 0.05 (39 --> 37) Core 2
- rb_float_to_bson ~ gain: 0.61 (15 --> 6, allocated: 3 --> 1) Core 2

Performance gains
-----------------

- catalog, extract techniques, tech talk

Driver notes
------------

Check for initial '$' or inclusion of '.' is purposely left to the driver.
See bench.rb: test_string_to_bson_key_mongodb



