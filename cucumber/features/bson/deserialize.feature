# language: en
@bson
Feature: Deserialize Documents 
  As a user of MongoDB
  In order to retreive data from the database
  I want the driver to deserialize documents

  Scenario Outline: Serialize Simple Documents
    Given an IO stream containing <hex_bytes>
    When I deserialize the stream
    Then the result should be the <type> value <value>

    Examples:
      | hex_bytes                              | type     | value      |
      | 10000000016b0026e4839ecd2a094000       | double   | 3.1459     |
      | 11000000026b0005000000746573740000     | string   | test       |
      | 13000000056b00060000000062696e61727900 | binary   | binary     |
      | 09000000086b000100                     | boolean  | true       |
      | 09000000086b000000                     | boolean  | false      |
      | 10000000096b008054e26bdc00000000       | datetime | 946702800  |
      | 080000000a6b0000                       | null     | null       |
      | 0f0000000b6b007265676578000000         | regex    | regex      |
      | 130000000e6b000700000073796d626f6c0000 | symbol   | symbol     |
      | 0c000000106b003930000000               | int32    | 12345      |
      | 10000000126b00000000800000000000       | int64    | 2147483648 |
      | 08000000ff6b0000                       | min_key  | min        |
      | 080000007f6b0000                       | max_key  | max        |
