# language: en
@bson
Feature: Serialize Elements 
  As a user of MongoDB
  In order to store data in the database
  The driver needs to serialize bson elements

  Scenario Outline: Serialize BSON Types
    Given a <value_type> value
    When I serialize the value
    Then the BSON element should have the BSON type <bson_type>

    Examples:
      | value_type   | bson_type |
      | double       | 01        |
      | string       | 02        |
      | document     | 03        |
      | array        | 04        |
      | binary       | 05        |
      | undefined    | 06        |
      | object_id    | 07        |
      | boolean      | 08        |
      | datetime     | 09        |
      | null         | 0A        |
      | regex        | 0B        |
      | db_pointer   | 0C        |
      | code         | 0D        |
      | symbol       | 0E        |
      | code_w_scope | 0F        |
      | int32        | 10        |
      | timestamp    | 11        |
      | int64        | 12        |
      | min_key      | FF        |
      | max_key      | 7F        |

  Scenario Outline: Serialize simple BSON Values
    Given a <value_type> value <value>
    When I serialize the value
    Then the result should be <hex_bytes>

    Examples:
      | value_type | value                    | hex_bytes                |
      | double     | 3.1459                   | 26e4839ecd2a0940         |
      | string     | test                     | 050000007465737400       | 
      | object_id  | 50d3409d82cb8a4fc7000001 | 50d3409d82cb8a4fc7000001 |
      | boolean    | false                    | 00                       |
      | boolean    | true                     | 01                       |
      | datetime   | 946702800                | 8054e26bdc000000         |
      | regex      | regex                    | 72656765780000           |
      | symbol     | symbol                   | 0700000073796d626f6c00   |
      | int32      | 12345                    | 39300000                 |
      | int64      | 2147483648               | 0000008000000000         |