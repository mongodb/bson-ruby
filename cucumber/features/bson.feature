# language: en
Feature: Serialize double 
  In order to serialize a BSON double element
  As a driver writer
  I want the result to be in accorance with the BSON specification

  Scenario Outline: Serialize double
    Given a key value <key>
    And a double value <value>
    When i serialize the key and value
    Then the result should be <hex_bytes>

  Examples:
    | key     | value   | hex_bytes                       |
    | pi      | 3.1459  | 0170690026e4839ecd2a0940        |
    | e       | 2.71828 | 01650090f7aa9509bf0540          | 
    | five    | 5.0     | 0166697665000000000000001440    |
    | neg     | -1000.0 | 016e6567000000000000408fc0      |
