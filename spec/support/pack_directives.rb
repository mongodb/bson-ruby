# frozen_string_literal: true

# Pack directives used by the test suite to build reference BSON encodings.
#
# These mirror the (now deprecated) BSON::Float::PACK, BSON::Int32::PACK, and
# BSON::Int64::PACK constants. The library no longer uses those constants
# internally, so the specs keep their own copies here rather than depending on
# deprecated production constants.
module PackDirectives
  # Pack directive for 8 byte floating points.
  FLOAT = 'E'

  # Pack directive for little-endian 32 bit integers.
  INT32 = 'l<'

  # Pack directive for little-endian 64 bit integers.
  INT64 = 'q<'
end
