BSON Changelog
==============

## 2.0.0

### Backwards Incompatible Changes

* `BSON::DEFAULT_MAX_BSON_SIZE` has been removed, as the BSON specification does not
  provide an upper limit on how large BSON documents can be.

* `BSON.serialize` is no longer the entry point to serialize a BSON document into its
  raw bytes.

      For Ruby runtimes that support ordered hashes, you may simply call `to_bson` on
      the hash instance (Alternatively a `BSON::Document` is also a hash:

        { key: "value" }.to_bson
        BSON::Document[:key, "value"].to_bson

      For Ruby runtimes that do not support ordered hashes, then you must instantiate
      an instance of a `BSON::Document` (which is a subclass of hash) and call `to_bson`
      on that, since the BSON specification guarantees order of the fields:

        BSON::Document[:key, "value"].to_bson

* `BSON.deserialize` is no longer the entry point for raw byte deserialization into
  a document.

      For Ruby runtimes that support ordered hashes, you may simply call `from_bson` on
      the `Hash` class if you want a `Hash` instance, or on `BSON::Document` if you
      want an instance of that. The input must be a `StringIO` object:

        Hash.from_bson(stringio)
        BSON::Document.from_bson(stringio)

      For Ruby runtimes that do not support ordered hashes, then `from_bson` must be
      called on `BSON::Document` in order to guarantee order:

        BSON::Document.from_bson(stringio)

### Features
