#
# Copyright (c) 2015-2020 "Neo Technology,"
# Network Engine for Objects in Lund AB [http://neotechnology.com]
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Attribution Notice under the terms of the Apache License 2.0
#
# This work was created by the collective efforts of the openCypher community.
# Without limiting the terms of Section 6, any Derivative Work that is not
# approved by the public consensus process of the openCypher Implementers Group
# should not be described as “Cypher” (and Cypher® is a registered trademark of
# Neo4j Inc.) or as "openCypher". Extensions by implementers or prototypes or
# proposals for change that have been documented or implemented should only be
# described as "implementation extensions to Cypher" or as "proposed changes to
# Cypher that are not yet approved by the openCypher community".
#

#encoding: utf-8

Feature: Merge1-1 - Merge Node and Match Interoperability

  Scenario: Should be able to merge using property from match
    Given an empty graph
    And having executed:
      """
      CREATE (:Person {name: 'A', bornIn: 'New York'})
      CREATE (:Person {name: 'B', bornIn: 'Ohio'})
      CREATE (:Person {name: 'C', bornIn: 'New Jersey'})
      CREATE (:Person {name: 'D', bornIn: 'New York'})
      CREATE (:Person {name: 'E', bornIn: 'Ohio'})
      CREATE (:Person {name: 'F', bornIn: 'New Jersey'})
      """
    When executing query:
      """
      MATCH (person:Person)
      MERGE (city:City {name: person.bornIn})
      """
    Then the result should be empty
    And the side effects should be:
      | +nodes      | 3 |
      | +labels     | 1 |
      | +properties | 3 |

  Scenario: Merge should be able to use properties of bound node in ON MATCH
    Given an empty graph
    And having executed:
      """
      CREATE (:Person {bornIn: 'New York'}),
        (:Person {bornIn: 'Ohio'})
      """
    When executing query:
      """
      MATCH (person:Person)
      MERGE (city:City)
        ON MATCH SET city.name = person.bornIn
      RETURN person.bornIn
      """
    Then the result should be, in any order:
      | person.bornIn |
      | 'New York'    |
      | 'Ohio'        |
    And the side effects should be:
      | +nodes      | 1 |
      | +labels     | 1 |
      | +properties | 1 |

  Scenario: Merge should be able to use properties of bound node in ON MATCH and ON CREATE
    Given an empty graph
    And having executed:
      """
      CREATE (:Person {bornIn: 'New York'}),
        (:Person {bornIn: 'Ohio'})
      """
    When executing query:
        """
        MATCH (person:Person)
        MERGE (city:City)
          ON MATCH SET city.name = person.bornIn
          ON CREATE SET city.name = person.bornIn
        RETURN person.bornIn
        """
    Then the result should be, in any order:
      | person.bornIn |
      | 'New York'    |
      | 'Ohio'        |
    And the side effects should be:
      | +nodes      | 1 |
      | +labels     | 1 |
      | +properties | 1 |
