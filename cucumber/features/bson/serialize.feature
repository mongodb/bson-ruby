# language: en
@bson
Feature: Serialize Documents 
  As a user of MongoDB
  In order to store data in the database
  I want the driver to serialize documents

  Scenario Outline: Serialize Simple Documents
    Given a document containing a <type> value <value>
    When I serialize the document
    Then the result should be <hex_bytes>

    Examples:
      | type     | value      | hex_bytes                              |
      | double   | 3.1459     | 10000000016b0026e4839ecd2a094000       |
      | string   | test       | 11000000026b0005000000746573740000     |
      | binary   | binary     | 13000000056b00060000000062696e61727900 |
      | boolean  | true       | 09000000086b000100                     |
      | boolean  | false      | 09000000086b000000                     |
      | datetime | 946702800  | 10000000096b008054e26bdc00000000       |
      | null     | null       | 080000000a6b0000                       |
      | regex    | regex      | 0f0000000b6b007265676578000000         |
      | symbol   | symbol     | 130000000e6b000700000073796d626f6c0000 |
      | int32    | 12345      | 0c000000106b003930000000               |
      | int64    | 2147483648 | 10000000126b00000000800000000000       |
      | min_key  | min        | 08000000ff6b0000                       |
      | max_key  | max        | 080000007f6b0000                       |

  Scenario Outline: Serialize Complex Documents
    Given a <document>
    When I serialize the document
    Then the result should be 
