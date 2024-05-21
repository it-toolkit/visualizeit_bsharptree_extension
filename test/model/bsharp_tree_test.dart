import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:visualizeit_bsharptree_extension/exception/element_insertion_exception.dart';
import 'package:visualizeit_bsharptree_extension/exception/element_not_found_exception.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_transition.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_tree.dart';

void main() {
  group("Insert value - ", () {
    test("first value inserting in an empty tree without splitting", () {
      var tree = BSharpTree<num>(3);
      tree.insert(150);
      expect(tree.nodesQuantity, 2);
      expect(tree.depth, 0);
      var transitions = tree.getTransitions();

      expect(transitions, hasLength(2));
      expect(transitions[0],
          predicate<NodeCreation>((t) => t.targetId == "0-1" && !t.hasTree()));
      expect(transitions[1],
          predicate<NodeWritten>((t) => t.targetId == "0-1" && t.hasTree()));
    });

    test('Root Splitting', () {
      var tree = BSharpTree<num>(3);
      tree.insertAll([150, 209, 113, 322]);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.insert(95);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting + 2);
      expect(depthAfterInserting, depthBeforeInserting + 1);

      var transitions = tree.getTransitions();
      expect(transitions, hasLength(8));
      expect(transitions[0], predicate<NodeRead>((t) => t.targetId == "0-1"));
      expect(transitions[1],
          predicate<NodeWritten>((t) => t.targetId == "0-1" && t.hasTree()));
      expect(transitions[2],
          predicate<NodeOverflow>((t) => t.targetId == "0-1" && t.hasTree()));
      expect(transitions[3],
          predicate<NodeCreation>((t) => t.targetId == "2" && !t.hasTree()));
      expect(transitions[4],
          predicate<NodeCreation>((t) => t.targetId == "3" && !t.hasTree()));
      expect(transitions[5],
          predicate<NodeWritten>((t) => t.targetId == "2" && t.hasTree()));
      expect(transitions[6],
          predicate<NodeWritten>((t) => t.targetId == "3" && !t.hasTree()));
      expect(transitions[7],
          predicate<NodeWritten>((t) => t.targetId == "0-1" && t.hasTree()));
    });

    test('Balancing sequential node to left sibling with available space', () {
      var tree = BSharpTree<num>(3);
      tree.insertAll([150, 209, 113, 322, 95]);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.insert(278);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting);
      expect(depthAfterInserting, depthBeforeInserting);

      var transitions = tree.getTransitions();
      expect(transitions, hasLength(8));
      expect(transitions[0], predicate<NodeRead>((t) => t.targetId == "0-1"));
      expect(transitions[1], predicate<NodeRead>((t) => t.targetId == "3"));
      expect(transitions[2],
          predicate<NodeWritten>((t) => t.targetId == "3" && t.hasTree()));
      expect(transitions[3],
          predicate<NodeOverflow>((t) => t.targetId == "3" && t.hasTree()));
      expect(transitions[4], predicate<NodeRead>((t) => t.targetId == "2"));
      expect(
          transitions[5],
          predicate<NodeBalancing>((t) =>
              t.targetId == "2" &&
              t.firstOptionalTarget == "3" &&
              t.hasTree()));
      expect(transitions[6],
          predicate<NodeWritten>((t) => t.targetId == "2" && !t.hasTree()));
      expect(transitions[7],
          predicate<NodeWritten>((t) => t.targetId == "3" && t.hasTree()));
    });

    test('Balancing in sequential node to right sibling with available space',
        () {
      var tree = BSharpTree<num>(3);
      tree.insertAll([150, 209, 113, 322, 95, 78, 23, 9]);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.insert(55);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting);
      expect(depthAfterInserting, depthBeforeInserting);

      var transitions = tree.getTransitions();
      expect(transitions, hasLength(8));
      expect(transitions[0], predicate<NodeRead>((t) => t.targetId == "0-1"));
      expect(transitions[1], predicate<NodeRead>((t) => t.targetId == "2"));
      expect(transitions[2],
          predicate<NodeWritten>((t) => t.targetId == "2" && t.hasTree()));
      expect(transitions[3],
          predicate<NodeOverflow>((t) => t.targetId == "2" && t.hasTree()));
      expect(transitions[4], predicate<NodeRead>((t) => t.targetId == "4"));
      expect(
          transitions[5],
          predicate<NodeBalancing>((t) =>
              t.targetId == "2" &&
              t.firstOptionalTarget == "4" &&
              t.hasTree()));
      expect(transitions[6],
          predicate<NodeWritten>((t) => t.targetId == "2" && !t.hasTree()));
      expect(transitions[7],
          predicate<NodeWritten>((t) => t.targetId == "4" && t.hasTree()));
    });

    test('full leaf nodes splitting (fusion with right sibling)', () {
      var tree = BSharpTree<num>(3);
      tree.insertAll([150, 209, 113, 322, 95, 278]);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.insert(12);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting + 1);
      expect(depthAfterInserting, depthBeforeInserting);

      var transitions = tree.getTransitions();
      expect(transitions, hasLength(9));
      expect(transitions[0], predicate<NodeRead>((t) => t.targetId == "0-1"));
      expect(transitions[1], predicate<NodeRead>((t) => t.targetId == "2"));
      expect(transitions[2],
          predicate<NodeWritten>((t) => t.targetId == "2" && t.hasTree()));
      expect(transitions[3],
          predicate<NodeOverflow>((t) => t.targetId == "2" && t.hasTree()));
      expect(transitions[4], predicate<NodeRead>((t) => t.targetId == "3"));
      expect(
          transitions[5],
          predicate<NodeSplit>((t) =>
              t.targetId == "2" &&
              t.firstOptionalTarget == "3" &&
              !t.hasTree()));
      expect(transitions[6],
          predicate<NodeCreation>((t) => t.targetId == "4" && !t.hasTree()));
      expect(transitions[7],
          predicate<NodeWritten>((t) => t.targetId == "4" && t.hasTree()));
      expect(transitions[8],
          predicate<NodeWritten>((t) => t.targetId == "0-1" && t.hasTree()));
    });

    test('full leaf nodes splitting (fusion with left sibling)', () {
      var tree = BSharpTree<num>(3);
      tree.insertAll([150, 209, 113, 322, 95, 278]);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.insert(305);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting + 1);
      expect(depthAfterInserting, depthBeforeInserting);

      var transitions = tree.getTransitions();
      expect(transitions, hasLength(9));
      expect(transitions[0], predicate<NodeRead>((t) => t.targetId == "0-1"));
      expect(transitions[1], predicate<NodeRead>((t) => t.targetId == "3"));
      expect(transitions[2],
          predicate<NodeWritten>((t) => t.targetId == "3" && t.hasTree()));
      expect(transitions[3],
          predicate<NodeOverflow>((t) => t.targetId == "3" && t.hasTree()));
      expect(transitions[4], predicate<NodeRead>((t) => t.targetId == "2"));
      expect(
          transitions[5],
          predicate<NodeSplit>((t) =>
              t.targetId == "2" &&
              t.firstOptionalTarget == "3" &&
              !t.hasTree()));
      expect(transitions[6],
          predicate<NodeCreation>((t) => t.targetId == "4" && !t.hasTree()));
      expect(transitions[7],
          predicate<NodeWritten>((t) => t.targetId == "4" && t.hasTree()));
      expect(transitions[8],
          predicate<NodeWritten>((t) => t.targetId == "0-1" && t.hasTree()));
    });

    test('index node splitting', () {
      var tree = BSharpTree<num>(3);
      tree.insertAll(
          [150, 209, 113, 322, 95, 278, 15, 74, 188, 525, 106, 137, 225]);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.insert(7);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting + 3);
      expect(depthAfterInserting, depthBeforeInserting + 1);

      var transitions = tree.getTransitions();
      expect(transitions, hasLength(15));
      expect(transitions[0], predicate<NodeRead>((t) => t.targetId == "0-1"));
      expect(transitions[1], predicate<NodeRead>((t) => t.targetId == "2"));
      expect(transitions[2],
          predicate<NodeWritten>((t) => t.targetId == "2" && t.hasTree()));
      expect(transitions[3],
          predicate<NodeOverflow>((t) => t.targetId == "2" && t.hasTree()));
      expect(transitions[4], predicate<NodeRead>((t) => t.targetId == "4"));
      expect(
          transitions[5],
          predicate<NodeSplit>((t) =>
              t.targetId == "2" &&
              t.firstOptionalTarget == "4" &&
              !t.hasTree()));
      expect(transitions[6],
          predicate<NodeCreation>((t) => t.targetId == "7" && !t.hasTree()));
      /*expect(transitions[2],
          predicate<NodeWritten>((t) => t.targetId == "3" && !t.hasTree()));
      expect(transitions[2],
          predicate<NodeWritten>((t) => t.targetId == "4" && !t.hasTree()));*/
      expect(transitions[7],
          predicate<NodeWritten>((t) => t.targetId == "7" && t.hasTree()));
      expect(transitions[8],
          predicate<NodeWritten>((t) => t.targetId == "0-1" && t.hasTree()));
      expect(transitions[9],
          predicate<NodeOverflow>((t) => t.targetId == "0-1" && t.hasTree()));
      expect(transitions[10],
          predicate<NodeCreation>((t) => t.targetId == "9" && !t.hasTree()));
      expect(transitions[11],
          predicate<NodeCreation>((t) => t.targetId == "8" && !t.hasTree()));
      expect(transitions[12],
          predicate<NodeWritten>((t) => t.targetId == "9" && !t.hasTree()));
      expect(transitions[13],
          predicate<NodeWritten>((t) => t.targetId == "8" && !t.hasTree()));
      expect(transitions[14],
          predicate<NodeWritten>((t) => t.targetId == "0-1" && t.hasTree()));
    });

    test('index node balancing, with rotation with right sibling', () {
      var tree = BSharpTree<num>(3);
      tree.insertAll([
        150,
        209,
        113,
        322,
        95,
        278,
        15,
        74,
        188,
        525,
        106,
        137,
        225,
        7,
        33,
        99,
        10
      ]);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.insert(121);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting + 1);
      expect(depthAfterInserting, depthBeforeInserting);

      var transitions = tree.getTransitions();
      expect(transitions, hasLength(15));
      expect(transitions[0], predicate<NodeRead>((t) => t.targetId == "0-1"));
      expect(transitions[1], predicate<NodeRead>((t) => t.targetId == "8"));
      expect(transitions[2], predicate<NodeRead>((t) => t.targetId == "4"));
      expect(transitions[3],
          predicate<NodeWritten>((t) => t.targetId == "4" && t.hasTree()));
      expect(transitions[4],
          predicate<NodeOverflow>((t) => t.targetId == "4" && t.hasTree()));
      expect(transitions[5], predicate<NodeRead>((t) => t.targetId == "7"));
      expect(
          transitions[6],
          predicate<NodeSplit>((t) =>
              t.targetId == "7" &&
              t.firstOptionalTarget == "4" &&
              !t.hasTree()));
      expect(transitions[7],
          predicate<NodeCreation>((t) => t.targetId == "11" && !t.hasTree()));
      expect(transitions[8],
          predicate<NodeWritten>((t) => t.targetId == "11" && t.hasTree()));
      expect(transitions[9],
          predicate<NodeWritten>((t) => t.targetId == "8" && t.hasTree()));
      expect(transitions[10],
          predicate<NodeOverflow>((t) => t.targetId == "8" && t.hasTree()));
      expect(transitions[11], predicate<NodeRead>((t) => t.targetId == "9"));
      expect(
          transitions[12],
          predicate<NodeBalancing>((t) =>
              t.targetId == "8" &&
              t.firstOptionalTarget == "9" &&
              t.hasTree()));
      expect(transitions[13],
          predicate<NodeWritten>((t) => t.targetId == "8" && !t.hasTree()));
      expect(transitions[14],
          predicate<NodeWritten>((t) => t.targetId == "9" && t.hasTree()));
    });

    test('index node balancing, with rotation with left sibling', () {
      var tree = BSharpTree<num>(3);
      tree.insertAll([
        150,
        209,
        113,
        322,
        95,
        278,
        15,
        74,
        188,
        525,
        106,
        137,
        225,
        7,
        166,
        264,
        192
      ]);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.insert(722);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting + 1);
      expect(depthAfterInserting, depthBeforeInserting);

      var transitions = tree.getTransitions();
      expect(transitions, hasLength(15));
      expect(transitions[0], predicate<NodeRead>((t) => t.targetId == "0-1"));
      expect(transitions[1], predicate<NodeRead>((t) => t.targetId == "9"));
      expect(transitions[2], predicate<NodeRead>((t) => t.targetId == "3"));
      expect(transitions[3],
          predicate<NodeWritten>((t) => t.targetId == "3" && t.hasTree()));
      expect(transitions[4],
          predicate<NodeOverflow>((t) => t.targetId == "3" && t.hasTree()));
      expect(transitions[5], predicate<NodeRead>((t) => t.targetId == "6"));
      expect(
          transitions[6],
          predicate<NodeSplit>((t) =>
              t.targetId == "6" &&
              t.firstOptionalTarget == "3" &&
              !t.hasTree()));
      expect(transitions[7],
          predicate<NodeCreation>((t) => t.targetId == "11" && !t.hasTree()));
      expect(transitions[8],
          predicate<NodeWritten>((t) => t.targetId == "11" && t.hasTree()));
      expect(transitions[9],
          predicate<NodeWritten>((t) => t.targetId == "9" && t.hasTree()));
      expect(transitions[10],
          predicate<NodeOverflow>((t) => t.targetId == "9" && t.hasTree()));
      expect(transitions[11], predicate<NodeRead>((t) => t.targetId == "8"));
      expect(
          transitions[12],
          predicate<NodeBalancing>((t) =>
              t.targetId == "8" &&
              t.firstOptionalTarget == "9" &&
              t.hasTree()));
      expect(transitions[13],
          predicate<NodeWritten>((t) => t.targetId == "8" && !t.hasTree()));
      expect(transitions[14],
          predicate<NodeWritten>((t) => t.targetId == "9" && t.hasTree()));
    });

    test('full index nodes splitting (fusion with right sibling)', () {
      var tree = BSharpTree<num>(3);
      tree.insertAll([
        150,
        209,
        113,
        322,
        95,
        278,
        15,
        74,
        188,
        525,
        106,
        137,
        225,
        7,
        33,
        99,
        10,
        121,
        2,
        21
      ]);
      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.insert(12);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting + 2);
      expect(depthAfterInserting, depthBeforeInserting);

      var transitions = tree.getTransitions();
      expect(transitions, hasLength(18));
      expect(transitions[0], predicate<NodeRead>((t) => t.targetId == "0-1"));
      expect(transitions[1], predicate<NodeRead>((t) => t.targetId == "8"));
      expect(transitions[2], predicate<NodeRead>((t) => t.targetId == "2"));
      expect(transitions[3],
          predicate<NodeWritten>((t) => t.targetId == "2" && t.hasTree()));
      expect(transitions[4],
          predicate<NodeOverflow>((t) => t.targetId == "2" && t.hasTree()));
      expect(transitions[5], predicate<NodeRead>((t) => t.targetId == "10"));
      expect(
          transitions[6],
          predicate<NodeSplit>((t) =>
              t.targetId == "2" &&
              t.firstOptionalTarget == "10" &&
              !t.hasTree()));
      expect(transitions[7],
          predicate<NodeCreation>((t) => t.targetId == "12" && !t.hasTree()));
      expect(transitions[8],
          predicate<NodeWritten>((t) => t.targetId == "12" && t.hasTree()));
      expect(transitions[9],
          predicate<NodeWritten>((t) => t.targetId == "8" && t.hasTree()));
      expect(transitions[10],
          predicate<NodeOverflow>((t) => t.targetId == "8" && t.hasTree()));
      expect(transitions[11], predicate<NodeRead>((t) => t.targetId == "9"));
      expect(
          transitions[12],
          predicate<NodeSplit>((t) =>
              t.targetId == "8" &&
              t.firstOptionalTarget == "9" &&
              !t.hasTree()));
      expect(transitions[13],
          predicate<NodeCreation>((t) => t.targetId == "13" && !t.hasTree()));
      expect(transitions[14],
          predicate<NodeWritten>((t) => t.targetId == "13" && !t.hasTree()));
      expect(transitions[15],
          predicate<NodeWritten>((t) => t.targetId == "8" && !t.hasTree()));
      expect(transitions[16],
          predicate<NodeWritten>((t) => t.targetId == "9" && t.hasTree()));
      expect(transitions[17],
          predicate<NodeWritten>((t) => t.targetId == "0-1" && t.hasTree()));
    });

    test('full index nodes splitting (fusion with left sibling)', () {
      var tree = BSharpTree<num>(2);
      tree.insertAll([150, 209, 113, 322, 95, 278, 15, 525, 674]);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.insert(589);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting + 2);
      expect(depthAfterInserting, depthBeforeInserting);

      var transitions = tree.getTransitions();
      expect(transitions, hasLength(18));
      expect(transitions[0], predicate<NodeRead>((t) => t.targetId == "0-1"));
      expect(transitions[1], predicate<NodeRead>((t) => t.targetId == "7"));
      expect(transitions[2], predicate<NodeRead>((t) => t.targetId == "3"));
      expect(transitions[3],
          predicate<NodeWritten>((t) => t.targetId == "3" && t.hasTree()));
      expect(transitions[4],
          predicate<NodeOverflow>((t) => t.targetId == "3" && t.hasTree()));
      expect(transitions[5], predicate<NodeRead>((t) => t.targetId == "9"));
      expect(
          transitions[6],
          predicate<NodeSplit>((t) =>
              t.targetId == "9" &&
              t.firstOptionalTarget == "3" &&
              !t.hasTree()));
      expect(transitions[7],
          predicate<NodeCreation>((t) => t.targetId == "10" && !t.hasTree()));
      expect(transitions[8],
          predicate<NodeWritten>((t) => t.targetId == "10" && t.hasTree()));
      expect(transitions[9],
          predicate<NodeWritten>((t) => t.targetId == "7" && t.hasTree()));
      expect(transitions[10],
          predicate<NodeOverflow>((t) => t.targetId == "7" && t.hasTree()));
      expect(transitions[11], predicate<NodeRead>((t) => t.targetId == "6"));
      expect(
          transitions[12],
          predicate<NodeSplit>((t) =>
              t.targetId == "6" &&
              t.firstOptionalTarget == "7" &&
              !t.hasTree()));
      expect(transitions[13],
          predicate<NodeCreation>((t) => t.targetId == "11" && !t.hasTree()));
      expect(transitions[14],
          predicate<NodeWritten>((t) => t.targetId == "11" && !t.hasTree()));
      expect(transitions[15],
          predicate<NodeWritten>((t) => t.targetId == "6" && !t.hasTree()));
      expect(transitions[16],
          predicate<NodeWritten>((t) => t.targetId == "7" && t.hasTree()));
      expect(transitions[17],
          predicate<NodeWritten>((t) => t.targetId == "0-1" && t.hasTree()));
    });

    test('4th level - random numbers', () {
      var tree = BSharpTree<num>(2);
      Random random = Random();
      Set<int> setOfInts = {};
      while (setOfInts.length < 25) {
        setOfInts.add(random.nextInt(1000));
      }

      tree.insertAll(setOfInts.toList());
      expect(tree.depth, 3);
    });

    test('5th level - random numbers ', () {
      var tree = BSharpTree<num>(2);
      Random random = Random();
      Set<int> setOfInts = {};
      while (setOfInts.length < 50) {
        setOfInts.add(random.nextInt(1000));
      }

      tree.insertAll(setOfInts.toList());
      expect(tree.depth, greaterThanOrEqualTo(3));

      List<int> shuffledList = setOfInts.toList();
      shuffledList.shuffle();

      for (var value in shuffledList) {
        tree.remove(value);
      }

      expect(tree.depth, 0);
    });

    test('same number insertion', () {
      var tree = BSharpTree<num>(2);
      tree.insert(150);
      tree.insert(209);
      tree.insert(113);
      tree.insert(322);
      tree.insert(95);
      expect(() => tree.insert(150),
          throwsA(const TypeMatcher<ElementInsertionException>()));
    });

    test('depth 0 when the tree is empty', () {
      var tree = BSharpTree<num>(2);
      expect(tree.depth, 0);
    });
  });

  group("remove value tests - ", () {
    test('element not found', () {
      var tree = BSharpTree<num>(3);
      tree.insertAll([10, 22, 150, 166]);

      expect(() => tree.remove(7),
          throwsA(const TypeMatcher<ElementNotFoundException>()));
    });

    test('remove with right sibling balancing', () {
      var tree = BSharpTree<num>(3);
      tree.insertAll([10, 22, 150, 166, 210, 233, 370, 421]);

      //int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.remove(22);

      //int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      //expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting + 2);
      expect(depthAfterInserting, depthBeforeInserting);

      var transitions = tree.getTransitions();
      expect(transitions, hasLength(8));
      expect(transitions[0], predicate<NodeRead>((t) => t.targetId == "0-1"));
      expect(transitions[1], predicate<NodeRead>((t) => t.targetId == "2"));
      expect(transitions[2],
          predicate<NodeWritten>((t) => t.targetId == "2" && t.hasTree()));
      expect(transitions[3],
          predicate<NodeUnderflow>((t) => t.targetId == "2" && t.hasTree()));
      expect(transitions[4], predicate<NodeRead>((t) => t.targetId == "4"));
      expect(
          transitions[5],
          predicate<NodeBalancing>((t) =>
              t.targetId == "2" &&
              t.firstOptionalTarget == "4" &&
              t.hasTree()));
      expect(transitions[6],
          predicate<NodeWritten>((t) => t.targetId == "2" && !t.hasTree()));
      expect(transitions[7],
          predicate<NodeWritten>((t) => t.targetId == "4" && t.hasTree()));
    });

    test('remove with left sibling balancing', () {
      var tree = BSharpTree<num>(3);
      tree.insertAll([10, 22, 150, 166, 233, 370]);
      tree.remove(233);

      //int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.remove(166);
      //int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      //expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting + 2);
      expect(depthAfterInserting, depthBeforeInserting);
      var transitions = tree.getTransitions();
      expect(transitions, hasLength(8));
      expect(transitions[0], predicate<NodeRead>((t) => t.targetId == "0-1"));
      expect(transitions[1], predicate<NodeRead>((t) => t.targetId == "3"));
      expect(transitions[2],
          predicate<NodeWritten>((t) => t.targetId == "3" && t.hasTree()));
      expect(transitions[3],
          predicate<NodeUnderflow>((t) => t.targetId == "3" && t.hasTree()));
      expect(transitions[4], predicate<NodeRead>((t) => t.targetId == "2"));
      expect(
          transitions[5],
          predicate<NodeBalancing>((t) =>
              t.targetId == "2" &&
              t.firstOptionalTarget == "3" &&
              t.hasTree()));
      expect(transitions[6],
          predicate<NodeWritten>((t) => t.targetId == "2" && !t.hasTree()));
      expect(transitions[7],
          predicate<NodeWritten>((t) => t.targetId == "3" && t.hasTree()));
    });

    test('remove with only two nodes - fusion with left sibling', () {
      var tree = BSharpTree<num>(3);
      tree.insertAll([10, 22, 150, 166, 210]);
      tree.remove(166);

      //int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.remove(150);

      //int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      //expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting + 2);
      expect(depthAfterInserting, depthBeforeInserting - 1);
      var transitions = tree.getTransitions();
      expect(transitions, hasLength(10));
      expect(transitions[0], predicate<NodeRead>((t) => t.targetId == "0-1"));
      expect(transitions[1], predicate<NodeRead>((t) => t.targetId == "3"));
      expect(transitions[2],
          predicate<NodeWritten>((t) => t.targetId == "3" && t.hasTree()));
      expect(transitions[3],
          predicate<NodeUnderflow>((t) => t.targetId == "3" && t.hasTree()));
      expect(transitions[4], predicate<NodeRead>((t) => t.targetId == "2"));
      expect(
          transitions[5],
          predicate<NodeFusion>((t) =>
              t.targetId == "2" &&
              t.firstOptionalTarget == "3" &&
              !t.hasTree()));
      expect(transitions[6],
          predicate<NodeWritten>((t) => t.targetId == "2" && !t.hasTree()));
      expect(transitions[7],
          predicate<NodeRelease>((t) => t.targetId == "3" && t.hasTree()));
      expect(transitions[8],
          predicate<NodeRelease>((t) => t.targetId == "2" && !t.hasTree()));
      expect(transitions[9],
          predicate<NodeWritten>((t) => t.targetId == "0-1" && t.hasTree()));
    });

    test('remove with only two nodes - fusion with right sibling', () {
      var tree = BSharpTree<num>(3);
      tree.insertAll([10, 22, 150, 166, 210]);
      tree.remove(166);

      //int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.remove(10);

      //int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      //expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting + 2);
      expect(depthAfterInserting, depthBeforeInserting - 1);
      var transitions = tree.getTransitions();
      expect(transitions, hasLength(10));
      expect(transitions[0], predicate<NodeRead>((t) => t.targetId == "0-1"));
      expect(transitions[1], predicate<NodeRead>((t) => t.targetId == "2"));
      expect(transitions[2],
          predicate<NodeWritten>((t) => t.targetId == "2" && t.hasTree()));
      expect(transitions[3],
          predicate<NodeUnderflow>((t) => t.targetId == "2" && t.hasTree()));
      expect(transitions[4], predicate<NodeRead>((t) => t.targetId == "3"));
      expect(
          transitions[5],
          predicate<NodeFusion>((t) =>
              t.targetId == "2" &&
              t.firstOptionalTarget == "3" &&
              !t.hasTree()));
      expect(transitions[6],
          predicate<NodeWritten>((t) => t.targetId == "2" && !t.hasTree()));
      expect(transitions[7],
          predicate<NodeRelease>((t) => t.targetId == "3" && t.hasTree()));
      expect(transitions[8],
          predicate<NodeRelease>((t) => t.targetId == "2" && !t.hasTree()));
      expect(transitions[9],
          predicate<NodeWritten>((t) => t.targetId == "0-1" && t.hasTree()));
    });

    test('remove with left and right siblings fusion', () {
      var tree = BSharpTree<num>(3);
      tree.insertAll([10, 22, 150, 166, 210, 233, 370]);
      tree.remove(233);

      //int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;
      tree.remove(150);

      //int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      //expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting + 2);
      expect(depthAfterInserting, depthBeforeInserting);
      var transitions = tree.getTransitions();
      expect(transitions, hasLength(11));
      expect(transitions[0], predicate<NodeRead>((t) => t.targetId == "0-1"));
      expect(transitions[1], predicate<NodeRead>((t) => t.targetId == "4"));
      expect(transitions[2],
          predicate<NodeWritten>((t) => t.targetId == "4" && t.hasTree()));
      expect(transitions[3],
          predicate<NodeUnderflow>((t) => t.targetId == "4" && t.hasTree()));
      expect(transitions[4], predicate<NodeRead>((t) => t.targetId == "3"));
      expect(transitions[5], predicate<NodeRead>((t) => t.targetId == "2"));
      expect(
          transitions[6],
          predicate<NodeFusion>((t) =>
              t.targetId == "4" &&
              t.firstOptionalTarget == "2" &&
              t.secondOptionalTargetId == "3" &&
              !t.hasTree()));
      expect(transitions[7],
          predicate<NodeWritten>((t) => t.targetId == "2" && !t.hasTree()));
      expect(transitions[8],
          predicate<NodeWritten>((t) => t.targetId == "3" && !t.hasTree()));
      expect(transitions[9],
          predicate<NodeRelease>((t) => t.targetId == "4" && t.hasTree()));
      expect(transitions[10],
          predicate<NodeWritten>((t) => t.targetId == "0-1" && t.hasTree()));
    });

    test('remove with two right siblings fusion', () {
      var tree = BSharpTree<num>(3);
      tree.insertAll([10, 22, 150, 166, 210, 233, 370]);
      tree.remove(233);

      //int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;
      tree.remove(10);

      //int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      //expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting + 2);
      expect(depthAfterInserting, depthBeforeInserting);
      var transitions = tree.getTransitions();
      expect(transitions, hasLength(11));
      expect(transitions[0], predicate<NodeRead>((t) => t.targetId == "0-1"));
      expect(transitions[1], predicate<NodeRead>((t) => t.targetId == "2"));
      expect(transitions[2],
          predicate<NodeWritten>((t) => t.targetId == "2" && t.hasTree()));
      expect(transitions[3],
          predicate<NodeUnderflow>((t) => t.targetId == "2" && t.hasTree()));
      expect(transitions[4], predicate<NodeRead>((t) => t.targetId == "4"));
      expect(transitions[5], predicate<NodeRead>((t) => t.targetId == "3"));
      expect(
          transitions[6],
          predicate<NodeFusion>((t) =>
              t.targetId == "4" &&
              t.firstOptionalTarget == "2" &&
              t.secondOptionalTargetId == "3" &&
              !t.hasTree()));
      expect(transitions[7],
          predicate<NodeWritten>((t) => t.targetId == "2" && !t.hasTree()));
      expect(transitions[8],
          predicate<NodeWritten>((t) => t.targetId == "3" && !t.hasTree()));
      expect(transitions[9],
          predicate<NodeRelease>((t) => t.targetId == "4" && t.hasTree()));
      expect(transitions[10],
          predicate<NodeWritten>((t) => t.targetId == "0-1" && t.hasTree()));
    });

    test('remove with two left sibling fusion', () {
      var tree = BSharpTree<num>(3);
      tree.insertAll([10, 22, 150, 166, 210, 233, 370]);
      tree.remove(233);

      //int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.remove(210);

      //int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      //expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting + 2);
      expect(depthAfterInserting, depthBeforeInserting);

      var transitions = tree.getTransitions();
      expect(transitions, hasLength(11));
      expect(transitions[0], predicate<NodeRead>((t) => t.targetId == "0-1"));
      expect(transitions[1], predicate<NodeRead>((t) => t.targetId == "3"));
      expect(transitions[2],
          predicate<NodeWritten>((t) => t.targetId == "3" && t.hasTree()));
      expect(transitions[3],
          predicate<NodeUnderflow>((t) => t.targetId == "3" && t.hasTree()));
      expect(transitions[4], predicate<NodeRead>((t) => t.targetId == "4"));
      expect(transitions[5], predicate<NodeRead>((t) => t.targetId == "2"));
      expect(
          transitions[6],
          predicate<NodeFusion>((t) =>
              t.targetId == "3" &&
              t.firstOptionalTarget == "2" &&
              t.secondOptionalTargetId == "4" &&
              !t.hasTree()));
      expect(transitions[7],
          predicate<NodeWritten>((t) => t.targetId == "2" && !t.hasTree()));
      expect(transitions[8],
          predicate<NodeWritten>((t) => t.targetId == "4" && !t.hasTree()));
      expect(transitions[9],
          predicate<NodeRelease>((t) => t.targetId == "3" && t.hasTree()));
      expect(transitions[10],
          predicate<NodeWritten>((t) => t.targetId == "0-1" && t.hasTree()));
    });

    test('remove with right sibling balancing on index node', () {
      var tree = BSharpTree<num>(2);
      tree.insertAll([10, 22, 150, 166, 210, 233, 370]);

      //int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.remove(22);

      //int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      //expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting + 2);
      expect(depthAfterInserting, depthBeforeInserting);

      var transitions = tree.getTransitions();
      expect(transitions, hasLength(15));

      expect(transitions[0], predicate<NodeRead>((t) => t.targetId == "0-1"));
      expect(transitions[1], predicate<NodeRead>((t) => t.targetId == "6"));
      expect(transitions[2], predicate<NodeRead>((t) => t.targetId == "4"));
      expect(transitions[3],
          predicate<NodeWritten>((t) => t.targetId == "4" && t.hasTree()));
      expect(transitions[4],
          predicate<NodeUnderflow>((t) => t.targetId == "4" && t.hasTree()));
      expect(transitions[5], predicate<NodeRead>((t) => t.targetId == "2"));
      expect(
          transitions[6],
          predicate<NodeFusion>((t) =>
              t.targetId == "2" &&
              t.firstOptionalTarget == "4" &&
              !t.hasTree()));
      expect(transitions[7],
          predicate<NodeWritten>((t) => t.targetId == "2" && !t.hasTree()));
      expect(transitions[8],
          predicate<NodeRelease>((t) => t.targetId == "4" && t.hasTree()));
      expect(transitions[9],
          predicate<NodeWritten>((t) => t.targetId == "6" && t.hasTree()));
      expect(transitions[10],
          predicate<NodeUnderflow>((t) => t.targetId == "6" && t.hasTree()));
      expect(transitions[11], predicate<NodeRead>((t) => t.targetId == "7"));
      expect(
          transitions[12],
          predicate<NodeBalancing>((t) =>
              t.targetId == "6" &&
              t.firstOptionalTarget == "7" &&
              t.hasTree()));
      expect(transitions[13],
          predicate<NodeWritten>((t) => t.targetId == "6" && !t.hasTree()));
      expect(transitions[14],
          predicate<NodeWritten>((t) => t.targetId == "7" && t.hasTree()));
      //expect(transitions[15],
      //    predicate<NodeWritten>((t) => t.targetId == "0-1" && t.hasTree()));
    });

    test('remove with left sibling balancing on index node', () {
      var tree = BSharpTree<num>(2);
      tree.insertAll([22, 36, 150, 166, 210, 121, 75, 17, 45]);
      tree.remove(166);
      tree.remove(121);

      //int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.remove(210);

      //int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      //expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting + 2);
      expect(depthAfterInserting, depthBeforeInserting);

      var transitions = tree.getTransitions();
      expect(transitions, hasLength(15));
      expect(transitions[0], predicate<NodeRead>((t) => t.targetId == "0-1"));
      expect(transitions[1], predicate<NodeRead>((t) => t.targetId == "7"));
      expect(transitions[2], predicate<NodeRead>((t) => t.targetId == "3"));
      expect(transitions[3],
          predicate<NodeWritten>((t) => t.targetId == "3" && t.hasTree()));
      expect(transitions[4],
          predicate<NodeUnderflow>((t) => t.targetId == "3" && t.hasTree()));
      expect(transitions[5], predicate<NodeRead>((t) => t.targetId == "4"));
      expect(
          transitions[6],
          predicate<NodeFusion>((t) =>
              t.targetId == "4" &&
              t.firstOptionalTarget == "3" &&
              !t.hasTree()));
      expect(transitions[7],
          predicate<NodeWritten>((t) => t.targetId == "4" && !t.hasTree()));
      expect(transitions[8],
          predicate<NodeRelease>((t) => t.targetId == "3" && t.hasTree()));
      expect(transitions[9],
          predicate<NodeWritten>((t) => t.targetId == "7" && t.hasTree()));
      expect(transitions[10],
          predicate<NodeUnderflow>((t) => t.targetId == "7" && t.hasTree()));
      expect(transitions[11], predicate<NodeRead>((t) => t.targetId == "6"));
      expect(
          transitions[12],
          predicate<NodeBalancing>((t) =>
              t.targetId == "6" &&
              t.firstOptionalTarget == "7" &&
              t.hasTree()));
      expect(transitions[13],
          predicate<NodeWritten>((t) => t.targetId == "6" && !t.hasTree()));
      expect(transitions[14],
          predicate<NodeWritten>((t) => t.targetId == "7" && t.hasTree()));
    });

    test('remove with index node fusion with right sibling', () {
      var tree = BSharpTree<num>(2);
      tree.insertAll([22, 36, 150, 166, 210, 121, 75]);
      tree.remove(150);
      tree.remove(121);
      tree.remove(75);

      //int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;
      tree.remove(22);

      //int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      //expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting + 2);
      expect(depthAfterInserting, depthBeforeInserting - 1);

      var transitions = tree.getTransitions();
      expect(transitions, hasLength(17));

      expect(transitions[0], predicate<NodeRead>((t) => t.targetId == "0-1"));
      expect(transitions[1], predicate<NodeRead>((t) => t.targetId == "6"));
      expect(transitions[2], predicate<NodeRead>((t) => t.targetId == "2"));
      expect(transitions[3],
          predicate<NodeWritten>((t) => t.targetId == "2" && t.hasTree()));
      expect(transitions[4],
          predicate<NodeUnderflow>((t) => t.targetId == "2" && t.hasTree()));
      expect(transitions[5], predicate<NodeRead>((t) => t.targetId == "5"));
      expect(
          transitions[6],
          predicate<NodeFusion>((t) =>
              t.targetId == "2" &&
              t.firstOptionalTarget == "5" &&
              !t.hasTree()));
      expect(transitions[7],
          predicate<NodeWritten>((t) => t.targetId == "2" && !t.hasTree()));
      expect(transitions[8],
          predicate<NodeRelease>((t) => t.targetId == "5" && t.hasTree()));
      expect(transitions[9],
          predicate<NodeWritten>((t) => t.targetId == "6" && t.hasTree()));
      expect(transitions[10],
          predicate<NodeUnderflow>((t) => t.targetId == "6" && t.hasTree()));
      expect(transitions[11], predicate<NodeRead>((t) => t.targetId == "7"));
      expect(
          transitions[12],
          predicate<NodeFusion>((t) =>
              t.targetId == "6" &&
              t.firstOptionalTarget == "7" &&
              !t.hasTree()));
      expect(transitions[13],
          predicate<NodeWritten>((t) => t.targetId == "6" && !t.hasTree()));
      expect(transitions[14],
          predicate<NodeRelease>((t) => t.targetId == "7" && !t.hasTree()));
      expect(transitions[15],
          predicate<NodeRelease>((t) => t.targetId == "6" && !t.hasTree()));
      expect(transitions[16],
          predicate<NodeWritten>((t) => t.targetId == "0-1" && t.hasTree()));
    });

    test('remove with index node fusion with left sibling', () {
      var tree = BSharpTree<num>(2);
      tree.insertAll([22, 36, 150, 166, 210, 121, 75]);
      tree.remove(150);
      tree.remove(121);
      tree.remove(75);

      int depthBeforeInserting = tree.depth;
      tree.remove(210);

      //int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      //expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting + 2);
      expect(depthAfterInserting, depthBeforeInserting - 1);

      var transitions = tree.getTransitions();
      expect(transitions, hasLength(17));
      expect(transitions[0], predicate<NodeRead>((t) => t.targetId == "0-1"));
      expect(transitions[1], predicate<NodeRead>((t) => t.targetId == "7"));
      expect(transitions[2], predicate<NodeRead>((t) => t.targetId == "3"));
      expect(transitions[3],
          predicate<NodeWritten>((t) => t.targetId == "3" && t.hasTree()));
      expect(transitions[4],
          predicate<NodeUnderflow>((t) => t.targetId == "3" && t.hasTree()));
      expect(transitions[5], predicate<NodeRead>((t) => t.targetId == "4"));
      expect(
          transitions[6],
          predicate<NodeFusion>((t) =>
              t.targetId == "4" &&
              t.firstOptionalTarget == "3" &&
              !t.hasTree()));
      expect(transitions[7],
          predicate<NodeWritten>((t) => t.targetId == "4" && !t.hasTree()));
      expect(transitions[8],
          predicate<NodeRelease>((t) => t.targetId == "3" && t.hasTree()));
      expect(transitions[9],
          predicate<NodeWritten>((t) => t.targetId == "7" && t.hasTree()));
      expect(transitions[10],
          predicate<NodeUnderflow>((t) => t.targetId == "7" && t.hasTree()));
      expect(transitions[11], predicate<NodeRead>((t) => t.targetId == "6"));
      expect(
          transitions[12],
          predicate<NodeFusion>((t) =>
              t.targetId == "6" &&
              t.firstOptionalTarget == "7" &&
              !t.hasTree()));
      expect(transitions[13],
          predicate<NodeWritten>((t) => t.targetId == "6" && !t.hasTree()));
      expect(transitions[14],
          predicate<NodeRelease>((t) => t.targetId == "7" && !t.hasTree()));
      expect(transitions[15],
          predicate<NodeRelease>((t) => t.targetId == "6" && !t.hasTree()));
      expect(transitions[16],
          predicate<NodeWritten>((t) => t.targetId == "0-1" && t.hasTree()));
    });

    test('remove with two right siblings balancing', () {
      var tree = BSharpTree<num>(3);
      tree.insertAll([10, 22, 150, 166, 210, 233, 370]);

      int depthBeforeInserting = tree.depth;
      tree.remove(22);

      //int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      //expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting + 2);
      expect(depthAfterInserting, depthBeforeInserting);

      var transitions = tree.getTransitions();
      expect(transitions, hasLength(10));
      expect(transitions[0], predicate<NodeRead>((t) => t.targetId == "0-1"));
      expect(transitions[1], predicate<NodeRead>((t) => t.targetId == "2"));
      expect(transitions[2],
          predicate<NodeWritten>((t) => t.targetId == "2" && t.hasTree()));
      expect(transitions[3],
          predicate<NodeUnderflow>((t) => t.targetId == "2" && t.hasTree()));
      expect(transitions[4], predicate<NodeRead>((t) => t.targetId == "4"));
      expect(transitions[5], predicate<NodeRead>((t) => t.targetId == "3"));
      expect(
          transitions[6],
          predicate<NodeBalancing>((t) =>
              t.targetId == "2" &&
              t.firstOptionalTarget == "4" &&
              t.secondOptionalTargetId == "3" &&
              t.hasTree()));
      expect(transitions[7],
          predicate<NodeWritten>((t) => t.targetId == "2" && !t.hasTree()));
      expect(transitions[8],
          predicate<NodeWritten>((t) => t.targetId == "4" && !t.hasTree()));
      expect(transitions[9],
          predicate<NodeWritten>((t) => t.targetId == "3" && t.hasTree()));
    });

    test('remove with two left siblings balancing', () {
      var tree = BSharpTree<num>(3);
      tree.insertAll([10, 22, 150, 166, 210, 75, 102, 56]);
      tree.remove(166);

      //int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;
      tree.remove(150);

      //int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      //expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting + 2);
      expect(depthAfterInserting, depthBeforeInserting);

      var transitions = tree.getTransitions();
      expect(transitions, hasLength(10));
      expect(transitions[0], predicate<NodeRead>((t) => t.targetId == "0-1"));
      expect(transitions[1], predicate<NodeRead>((t) => t.targetId == "3"));
      expect(transitions[2],
          predicate<NodeWritten>((t) => t.targetId == "3" && t.hasTree()));
      expect(transitions[3],
          predicate<NodeUnderflow>((t) => t.targetId == "3" && t.hasTree()));
      expect(transitions[4], predicate<NodeRead>((t) => t.targetId == "4"));
      expect(transitions[5], predicate<NodeRead>((t) => t.targetId == "2"));
      expect(
          transitions[6],
          predicate<NodeBalancing>((t) =>
              t.targetId == "2" &&
              t.firstOptionalTarget == "4" &&
              t.secondOptionalTargetId == "3" &&
              t.hasTree()));
      expect(transitions[7],
          predicate<NodeWritten>((t) => t.targetId == "2" && !t.hasTree()));
      expect(transitions[8],
          predicate<NodeWritten>((t) => t.targetId == "4" && !t.hasTree()));
      expect(transitions[9],
          predicate<NodeWritten>((t) => t.targetId == "3" && t.hasTree()));
    });
  });

  group("Obtain all nodes in a map", () {
    test('one level tree', () {
      var tree = BSharpTree<num>(3);
      tree.insertAll([10, 22, 150, 90]);
      var allNodesByLevel = tree.getAllNodesByLevel();

      expect(allNodesByLevel.length, 1);
      expect(allNodesByLevel[0]!.length, 1);
    });

    test('two level tree', () {
      var tree = BSharpTree<num>(3);
      tree.insertAll([10, 22, 150, 90, 76]);

      var allNodesByLevel = tree.getAllNodesByLevel();

      expect(allNodesByLevel.length, 2);
      expect(allNodesByLevel[0]!.length, 2);
      expect(allNodesByLevel[1]!.length, 1);
    });

    test('three level tree', () {
      var tree = BSharpTree<num>(3);
      tree.insertAll([
        150,
        209,
        113,
        322,
        95,
        278,
        15,
        74,
        188,
        525,
        106,
        137,
        225,
        7,
        166,
        264,
        192,
        722
      ]);

      var allNodesByLevel = tree.getAllNodesByLevel();

      expect(allNodesByLevel.length, 3);
      expect(allNodesByLevel[0]!.length, 8);
      expect(allNodesByLevel[1]!.length, 2);
      expect(allNodesByLevel[2]!.length, 1);
    });
  });
}
