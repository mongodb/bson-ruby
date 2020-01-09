There are the following deliberate changes made to the corpus tests in Ruby:

1. In double.js, Ruby appears to offer less precision than the spec tests
demand:

    irb(main):001:0> -1.23456789012345677E+18
    => -1.2345678901234568e+18

Because of this, -1.23456789012345677E+18 was changed to -1.2345678901234568e+18.
The "e" was lowercased as well. Both the precision reduction and the lowercasing
of "e" changes are also present in the Python driver, which appears to be
affected by the same precision limitation.

2. In datetime.js, the millisecond component of iso8601 serialization of
timestamps is always present, even if it is zero.
