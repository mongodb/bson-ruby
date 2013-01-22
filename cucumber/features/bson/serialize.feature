# language: en
@bson
Feature: Serialize Documents 
  As a user of MongoDB
  In order to store data in the database
  I want the driver to serialize documents

  Scenario Outline: Serialize BSON Types
    Given a <value_type> value
    When I serialize the value
    Then the BSON element has the BSON type <bson_type>

    Examples:
      | value_type   | bson_type |
      | double       | 0x01      |
      | string       | 0x02      |
      | document     | 0x03      |
      | array        | 0x04      |
      | binary       | 0x05      |
      | undefined    | 0x06      |
      | object_id    | 0x07      |
      | boolean      | 0x08      |
      | datetime     | 0x09      |
      | null         | 0x0A      |
      | regex        | 0x0B      |
      | db_pointer   | 0x0C      |
      | code         | 0x0D      |
      | symbol       | 0x0E      |
      | code_w_scope | 0x0F      |
      | int32        | 0x10      |
      | timestamp    | 0x11      |
      | int64        | 0x12      |
      | min_key      | 0xFF      |
      | max_key      | 0x7F      |

  Scenario Outline: Serialize scalar BSON Values
    Given <type> value <value>
    When I serialize the value
    Then the result should be <hex_bytes>

    Examples:
      | type       | value                    | hex_bytes                |
      | double     | 3.1459                   | 26e4839ecd2a0940         |
      | string     | test                     | 050000007465737400       | 
      | binary     | binary                   | 62696e617279             |
      | objectid   | 50d3409d82cb8a4fc7000001 | 50d3409d82cb8a4fc7000001 |
      | boolean    | false                    | 00                       |
      | boolean    | true                     | 01                       |
      | datetime   | 946702800                | 8054e26bdc000000         |
      | regex      | regex                    | 72656765780000           |
      | db_pointer |                          |                          |
      | code       | function(){}             |                          |
      | symbol     | symbol                   | 0700000073796d626f6c00   |
      | int32      | 12345                    | 39300000                 |
      | timestamp  |                          |                          |
      | int64      | 2147483648               | 0000008000000000         |