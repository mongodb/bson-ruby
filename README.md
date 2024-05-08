BSON
[![Gem Version][rubygems-img]][rubygems-url]
[![Build Status][ghactions-img]][ghactions-url]
[![Coverage Status][coveralls-img]][coveralls-url]
[![Inline docs][inch-img]][inch-url]
====

An implementation of the BSON specification in Ruby.

Compatibility
-------------

BSON is tested against MRI (2.6) and JRuby (9.2+).

Documentation
-------------

Current documentation can be found
[here](https://www.mongodb.com/docs/ruby-driver/current/bson-tutorials/).

API Documentation
-----------------

The [API Documentation](https://www.mongodb.com/docs/ruby-driver/master/api/) is
located at mongodb.com/docs.

BSON Specification
------------------

The [BSON specification](http://bsonspec.org) is at bsonspec.org.

## Bugs & Feature Requests

To report a bug in the `bson` gem or request a feature:

1. Visit [our issue tracker](https://jira.mongodb.org/) and login
   (or create an account if you do not have one already).
2. Navigate to the [RUBY project](https://jira.mongodb.org/browse/RUBY).
3. Click 'Create Issue' and fill out all of the applicable form fields, making
sure to select `BSON` in the _Component/s_ field.

When creating an issue, please keep in mind that all information in JIRA
for the RUBY project, as well as the core server (the SERVER project),
is publicly visible.

**PLEASE DO:**

- Provide as much information as possible about the issue.
- Provide detailed steps for reproducing the issue.
- Provide any applicable code snippets, stack traces and log data.
- Specify version numbers of the `bson` gem and/or Ruby driver and MongoDB 
server.

**PLEASE DO NOT:**

- Provide any sensitive data or server logs.
- Report potential security issues publicly (see 'Security Issues' below).

## Security Issues

If you have identified a potential security-related issue in the `bson` gem
(or any other MongoDB product), please report it by following the
[instructions here](https://www.mongodb.com/docs/manual/tutorial/create-a-vulnerability-report).

## Product Feature Requests

To request a feature which is not specific to the `bson` gem, or which
affects more than the `bson` gem and/or Ruby driver alone (for example, a 
feature which requires MongoDB server support), please submit your idea through 
the [MongoDB Feedback Forum](https://feedback.mongodb.com/forums/924286-drivers).

## Maintenance and Bug Fix Policy

New library functionality is generally added in a backwards-compatible manner
and results in new minor releases. Bug fixes are generally made on
master first and are backported to the current minor library release. Exceptions
may be made on a case-by-case basis, for example security fixes may be
backported to older stable branches. Only the most recent minor release
is officially supported. Customers should use the most recent release in
their applications.

Versioning
----------

As of 2.0.0, this project adheres to the
[Semantic Versioning Specification](http://semver.org/).

License
-------

Copyright (C) 2009-2020 MongoDB Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

[rubygems-img]: https://badge.fury.io/rb/bson.svg
[rubygems-url]: http://badge.fury.io/rb/bson
[ghactions-img]: https://github.com/mongodb/bson-ruby/actions/workflows/bson-ruby.yml/badge.svg?query=branch%3Amaster
[ghactions-url]: https://github.com/mongodb/bson-ruby/actions/workflows/bson-ruby.yml?query=branch%3Amaster
[coveralls-img]: https://coveralls.io/repos/mongodb/bson-ruby/badge.svg?branch=master
[coveralls-url]: https://coveralls.io/r/mongodb/bson-ruby?branch=master
[inch-img]: http://inch-ci.org/github/mongodb/bson-ruby.svg?branch=master
[inch-url]: http://inch-ci.org/github/mongodb/bson-ruby
