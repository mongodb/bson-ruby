# Project Description

This is the Ruby implementation of the BSON (Binary JSON) specification. BSON is the binary-encoded serialization format used by MongoDB. This library provides serialization and deserialization of BSON data, Ruby type extensions for BSON-compatible types, and a C native extension for performance-critical operations. The library targets Ruby 2.6+. Do not use syntax or stdlib features unavailable in Ruby 2.6.

# Project Structure

- `lib/`: the main Ruby codebase
- `ext/bson/`: C native extension for MRI Ruby (performance-critical serialization)
- `src/`: Java extension source for JRuby
- `spec/`: RSpec tests and shared test data
- `spec/spec_tests/`: specification-driven tests with YAML fixtures from the BSON specification
- `perf/`: benchmarking scripts


# Development Workflow

## Running tests

Tests do not require a running MongoDB instance. Run specs with:

```
bundle exec rake spec
```

This compiles the native extension and runs the full test suite. To run a single spec file:

```
bundle exec rspec spec/path/to/spec.rb
```

Note: the native extension must be compiled before running specs directly with `rspec`. Use `bundle exec rake compile` first if needed.

## Linting

Run RuboCop after making changes, and always before committing:

```
bundle exec rubocop lib/bson/changed_file.rb spec/bson/changed_file_spec.rb
```

Pass the specific files you modified.

RuboCop is configured with performance, rake, and rspec plugins (`.rubocop.yml`).

## Commit convention

Prefix commit messages with the JIRA ticket: `RUBY-#### Short description`. The ticket number is typically in the branch name.

## Prose style

When writing prose — commit messages, code comments, documentation — be concise, write as a human would, avoid overly complicated sentences, and use no emojis.

## Definition of done

Always run the relevant spec file(s) before considering a task complete. Running tests is not optional. "Relevant" means: the spec file for each class you changed, plus any spec tests in `spec/spec_tests/` that exercise the affected type. If the native extension fails to compile, report this to the user rather than trying to work around it.

## Native extensions

This library includes a C extension (`ext/bson/`) for MRI and a Java extension (`src/`) for JRuby. When modifying serialization or deserialization behavior, check whether the native extension also needs updating. The C extension must remain compatible with the pure-Ruby fallback in `lib/`.

## Spec fixtures

BSON specification test YAML fixtures live in `spec/spec_tests/data/`. These are shared across all BSON implementations and are not owned by this repository. Do not modify them.

Do not write Ruby specs that duplicate behavior already covered by YAML spec tests. New Ruby specs should cover behavior that cannot be expressed in the specification test format.


# Code Reviews

See [.github/code-review.md](.github/code-review.md) for code review guidelines.
