BSON [![Build Status](https://secure.travis-ci.org/mongodb/bson-ruby.png?branch=master&.png)](http://travis-ci.org/mongodb/bson-ruby) [![Code Climate](https://codeclimate.com/github/mongodb/bson-ruby.png)](https://codeclimate.com/github/mongodb/bson-ruby) [![Coverage Status](https://coveralls.io/repos/mongodb/bson-ruby/badge.png?branch=master)](https://coveralls.io/r/mongodb/bson-ruby?branch=master)
====

An implementation of the BSON specification in Ruby.

Compatibility
-------------

BSON is tested against MRI (1.9.2+), JRuby (1.7.0+) and Rubinius (2.0.0+).

Installation
------------

With bundler, add the `bson` gem to your `Gemfile`. As of 2.0.0 native extensions
are bundled with the `bson` gem and `bson_ext` is no longer needed.

```ruby
gem "bson", "~> 2.2"
```

Require the `bson` gem in your application.

```ruby
require "bson"
```

Usage
-----

### BSON Serialization

Getting a Ruby object's raw BSON representation is done by calling `to_bson`
on the Ruby object. For example:

```ruby
"Shall I compare thee to a summer's day".to_bson
1024.to_bson
```

Generating an object from BSON is done via calling `from_bson` on the class
you wish to instantiate and passing it the `StringIO` bytes.

```ruby
String.from_bson(string_io)
Int32.from_bson(string_io)
```

Core Ruby object's that have representations in the BSON specification and
will have a `to_bson` method defined for them are:

- `Array`
- `FalseClass`
- `Float`
- `Hash`
- `Integer`
- `NilClass`
- `Regexp`
- `String`
- `Symbol` (deprecated)
- `Time`
- `TrueClass`

In addition to the core Ruby objects, BSON also provides some special types
specific to the specification:

#### `BSON::Binary`

This is a representation of binary data, and must provide the raw data and
a subtype when constructing.

```ruby
BSON::Binary.new(binary_data, :md5)
```

Valid subtypes are: `:generic`, `:function`, `:old`, `:uuid_old`, `:uuid`,
`:md5`, `:user`.

#### `BSON::Code`

Represents a string of Javascript code.

```ruby
BSON::Code.new("this.value = 5;")
```

#### `BSON::CodeWithScope`

Represents a string of Javascript code with a hash of values.

```ruby
BSON::CodeWithScope.new("this.value = age;", age: 5)
```

#### `BSON::Document`

This is a special ordered hash for use with Ruby below 1.9, and is simply
a subclass of a Ruby hash in 1.9 and higher.

```ruby
BSON::Document[:key, "value"]
BSON::Document.new
```

#### `BSON::MaxKey`

Represents a value in BSON that will always compare higher to another value.

```ruby
BSON::MaxKey.new
```

#### `BSON::MinKey`

Represents a value in BSON that will always compare lower to another value.

```ruby
BSON::MinKey.new
```

#### `BSON::ObjectId`

Represents a 12 byte unique identifier for an object on a given machine.

```ruby
BSON::ObjectId.new
```

#### `BSON::Timestamp`

Represents a special time with a start and increment value.

```ruby
BSON::Timestamp.new(5, 30)
```

#### `BSON::Undefined`

Represents a placeholder for a value that was not provided.

```ruby
BSON::Undefined.new
```

### JSON Serialization

Some BSON types have special representations in JSON. These are as follows
and will be automatically serialized in the form when calling `to_json` on
them.

- `BSON::Binary`: `{ "$binary" : "\x01", "$type" : "md5" }`
- `BSON::Code`: `{ "$code" : "this.v = 5 }`
- `BSON::CodeWithScope`: `{ "$code" : "this.v = value", "$scope" : { v => 5 }}`
- `BSON::MaxKey`: `{ "$maxKey" : 1 }`
- `BSON::MinKey`: `{ "$minKey" : 1 }`
- `BSON::ObjectId`: `{ "$oid" : "4e4d66343b39b68407000001" }`
- `BSON::Timestamp`: `{ "t" : 5, "i" : 30 }`
- `Regexp`: `{ "$regex" : "[abc]", "$options" : "i" }`

### Notes on Special Ruby Date Classes

As of 2.1.0, Ruby's `Date` and `DateTime` are able to be serialized, but when
they are deserialized they will always be returned as a `Time` since the BSON
specification only has a `Time` type and knows nothing about Ruby.

API Documentation
-----------------

The [API Documentation](http://rdoc.info/github/mongodb/bson-ruby/master/frames) is
located at rdoc.info.

BSON Specification
------------------

The [BSON specification](http://bsonspec.org) is at bsonspec.org.

Versioning
----------

As of 2.0.0, this project adheres to the [Semantic Versioning Specification](http://semver.org/).

License
-------

Copyright (C) 2009-2013 MongoDB Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
