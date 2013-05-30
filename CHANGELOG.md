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

### Features
