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

Feature: ReturnAcceptance2

  # Consider moving to feature on RETURN clause's aggregates on complex expressions capability
  Scenario: Arithmetic expressions inside aggregation
    Given an empty graph
    And having executed:
      """
      CREATE (andres {name: 'Andres'}),
             (michael {name: 'Michael'}),
             (peter {name: 'Peter'}),
             (bread {type: 'Bread'}),
             (veggies {type: 'Veggies'}),
             (meat {type: 'Meat'})
      CREATE (andres)-[:ATE {times: 10}]->(bread),
             (andres)-[:ATE {times: 8}]->(veggies),
             (michael)-[:ATE {times: 4}]->(veggies),
             (michael)-[:ATE {times: 6}]->(bread),
             (michael)-[:ATE {times: 9}]->(meat),
             (peter)-[:ATE {times: 7}]->(veggies),
             (peter)-[:ATE {times: 7}]->(bread),
             (peter)-[:ATE {times: 4}]->(meat)
      """
    When executing query:
      """
      MATCH (me)-[r1:ATE]->()<-[r2:ATE]-(you)
      WHERE me.name = 'Michael'
      WITH me, count(DISTINCT r1) AS H1, count(DISTINCT r2) AS H2, you
      MATCH (me)-[r1:ATE]->()<-[r2:ATE]-(you)
      RETURN me, you, sum((1 - abs(r1.times / H1 - r2.times / H2)) * (r1.times + r2.times) / (H1 + H2)) AS sum
      """
    Then the result should be, in any order:
      | me                  | you                | sum |
      | ({name: 'Michael'}) | ({name: 'Andres'}) | -7  |
      | ({name: 'Michael'}) | ({name: 'Peter'})  | 0   |
    And no side effects

  Scenario: Matching and disregarding output, then matching again
    Given an empty graph
    And having executed:
      """
      CREATE (andres {name: 'Andres'}),
             (michael {name: 'Michael'}),
             (peter {name: 'Peter'}),
             (bread {type: 'Bread'}),
             (veggies {type: 'Veggies'}),
             (meat {type: 'Meat'})
      CREATE (andres)-[:ATE {times: 10}]->(bread),
             (andres)-[:ATE {times: 8}]->(veggies),
             (michael)-[:ATE {times: 4}]->(veggies),
             (michael)-[:ATE {times: 6}]->(bread),
             (michael)-[:ATE {times: 9}]->(meat),
             (peter)-[:ATE {times: 7}]->(veggies),
             (peter)-[:ATE {times: 7}]->(bread),
             (peter)-[:ATE {times: 4}]->(meat)
      """
    When executing query:
      """
      MATCH ()-->()
      WITH 1 AS x
      MATCH ()-[r1]->()<--()
      RETURN sum(r1.times)
      """
    Then the result should be, in any order:
      | sum(r1.times) |
      | 776           |
    And no side effects

  Scenario: Multiple aliasing and backreferencing
    Given any graph
    When executing query:
      """
      CREATE (m {id: 0})
      WITH {first: m.id} AS m
      WITH {second: m.first} AS m
      RETURN m.second
      """
    Then the result should be, in any order:
      | m.second |
      | 0        |
    And the side effects should be:
      | +nodes      | 1 |
      | +properties | 1 |

  Scenario: Reusing variable names
    Given an empty graph
    And having executed:
      """
      CREATE (a:Person), (b:Person), (m:Message {id: 10})
      CREATE (a)-[:LIKE {creationDate: 20160614}]->(m)-[:POSTED_BY]->(b)
      """
    When executing query:
      """
      MATCH (person:Person)<--(message)<-[like]-(:Person)
      WITH like.creationDate AS likeTime, person AS person
        ORDER BY likeTime, message.id
      WITH head(collect({likeTime: likeTime})) AS latestLike, person AS person
      RETURN latestLike.likeTime AS likeTime
        ORDER BY likeTime
      """
    Then the result should be, in order:
      | likeTime |
      | 20160614 |
    And no side effects
