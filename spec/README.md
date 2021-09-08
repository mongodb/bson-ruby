# Running BSON Ruby Tests

## Quick Start

The test suite requires shared tooling that is stored in a separate repository
and is referenced as a submodule. After checking out the desired bson-ruby
branch, check out the matching submodules:

    git submodule init
    git submodule update

Then, to run the test suite:

    rake
