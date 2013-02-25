# language: en
@bson
Feature: Serialize Elements 
  As a user of MongoDB
  In order to store data in the database
  The driver needs to serialize bson elements

  Scenario Outline: Serialize BSON types
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

  Scenario Outline: Serialize simple BSON values
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

  Scenario: Serialize hash value
    Given a hash with the following items:
      | key    | value_type | value |
      | double | double     | 3.14  |
      | string | string     | test  |
      | int32  | int32      | 1234  |
    When I serialize the value
    Then the result should be the bson document:
      | bson_type | e_name | value              |
      | 01        | double | 1f85eb51b81e0940   |
      | 02        | string | 050000007465737400 |
      | 10        | int32  | d2040000           |

  Scenario: Serialize array value
    Given a array with the following items:
      | value_type | value |
      | double     | 3.14  |
      | string     | test  |
      | int32      | 1234  |
    When I serialize the value
    Then the result should be the bson document:
      | bson_type | e_name | value              |
      | 01        | 0      | 1f85eb51b81e0940   |
      | 02        | 1      | 050000007465737400 |
      | 10        | 2      | d2040000           |

  Scenario Outline: Serialize binary values
    Given a binary value <value> with binary type <binary_type>
    When I serialize the value
    Then the result should be <hex_bytes>

    Examples:
      | value | binary_type | hex_bytes                  |
      | data  | generic     | 080000000064617461         |
      | data  | function    | 080000000164617461         |
      | data  | old         | 0c000000020400000064617461 |
      | data  | uuid_old    | 080000000364617461         |
      | data  | uuid        | 080000000464617461         |
      | data  | md5         | 080000000564617461         |
      | data  | user        | 080000008064617461         |

  Scenario Outline: Serialize code values
    Given a code value <code> with scope <scope>
    When I serialize the value
    Then the result should be <hex_bytes>

    Examples:
      | code         | scope     | hex_bytes |
      | function(){} |           |           |
      | function(){} | {:a => 1} |           |