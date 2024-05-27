import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:visualizeit_bsharptree_extension/exception/element_insertion_exception.dart';
import 'package:visualizeit_bsharptree_extension/exception/element_not_found_exception.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_tree.dart';
import 'package:visualizeit_bsharptree_extension/model/tree_logger_observer.dart';

void main() {
  group("Insert value - ", () {
    test("first value inserting in an empty tree without splitting", () {
      var tree = BSharpTree<num>(3);
      TreeLoggerObserver(tree);
      tree.insert(150);
      expect(tree.nodesQuantity, 2);
      expect(tree.depth, 0);
    });

    test('Root Splitting', () {
      var tree = BSharpTree<num>(3);
      TreeLoggerObserver(tree);
      tree.insertAll([150, 209, 113, 322]);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.insert(95);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting + 2);
      expect(depthAfterInserting, depthBeforeInserting + 1);
    });

    test('Balancing sequential node to left sibling with available space', () {
      var tree = BSharpTree<num>(3);
      TreeLoggerObserver(tree);
      tree.insertAll([150, 209, 113, 322, 95]);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.insert(278);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting);
      expect(depthAfterInserting, depthBeforeInserting);
    });

    test('Balancing in sequential node to right sibling with available space',
        () {
      var tree = BSharpTree<num>(3);
      TreeLoggerObserver(tree);
      tree.insertAll([150, 209, 113, 322, 95, 78, 23, 9]);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.insert(55);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting);
      expect(depthAfterInserting, depthBeforeInserting);
    });

    test('full leaf nodes splitting (fusion with right sibling)', () {
      var tree = BSharpTree<num>(3);
      TreeLoggerObserver(tree);
      tree.insertAll([150, 209, 113, 322, 95, 278]);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.insert(12);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting + 1);
      expect(depthAfterInserting, depthBeforeInserting);
    });

    test('full leaf nodes splitting (fusion with left sibling)', () {
      var tree = BSharpTree<num>(3);
      TreeLoggerObserver(tree);
      tree.insertAll([150, 209, 113, 322, 95, 278]);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.insert(305);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting + 1);
      expect(depthAfterInserting, depthBeforeInserting);
    });

    test('index node splitting', () {
      var tree = BSharpTree<num>(3);
      TreeLoggerObserver(tree);
      tree.insertAll(
          [150, 209, 113, 322, 95, 278, 15, 74, 188, 525, 106, 137, 225]);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.insert(7);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting + 3);
      expect(depthAfterInserting, depthBeforeInserting + 1);
    });

    test('index node balancing, with rotation with right sibling', () {
      var tree = BSharpTree<num>(3);
      TreeLoggerObserver(tree);
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
    });

    test('index node balancing, with rotation with left sibling', () {
      var tree = BSharpTree<num>(3);
      TreeLoggerObserver(tree);
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
    });

    test('full index nodes splitting (fusion with right sibling)', () {
      var tree = BSharpTree<num>(3);
      TreeLoggerObserver(tree);
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
    });

    test('full index nodes splitting (fusion with left sibling)', () {
      var tree = BSharpTree<num>(2);
      TreeLoggerObserver(tree);
      tree.insertAll([150, 209, 113, 322, 95, 278, 15, 525, 674]);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.insert(589);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting + 2);
      expect(depthAfterInserting, depthBeforeInserting);
    });

    test('4th level - random numbers', () {
      var tree = BSharpTree<num>(2);
      TreeLoggerObserver(tree);
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
      TreeLoggerObserver(tree);
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
      TreeLoggerObserver(tree);
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
      TreeLoggerObserver(tree);
      expect(tree.depth, 0);
    });
  });

  group("remove value tests - ", () {
    test('element not found', () {
      var tree = BSharpTree<num>(3);
      TreeLoggerObserver(tree);
      tree.insertAll([10, 22, 150, 166]);

      expect(() => tree.remove(7),
          throwsA(const TypeMatcher<ElementNotFoundException>()));
    });

    test('remove with right sibling balancing', () {
      var tree = BSharpTree<num>(3);
      TreeLoggerObserver(tree);
      tree.insertAll([10, 22, 150, 166, 210, 233, 370, 421]);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.remove(22);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting);
      expect(depthAfterInserting, depthBeforeInserting);

      expect(tree.freeNodesIds, isEmpty);
    });

    test('remove with left sibling balancing', () {
      var tree = BSharpTree<num>(3);
      TreeLoggerObserver(tree);
      tree.insertAll([10, 22, 150, 166, 233, 370]);
      tree.remove(233);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.remove(166);
      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting);
      expect(depthAfterInserting, depthBeforeInserting);

      expect(tree.freeNodesIds, isEmpty);
    });

    test('remove with only two nodes - fusion with left sibling', () {
      var tree = BSharpTree<num>(3);
      TreeLoggerObserver(tree);
      tree.insertAll([10, 22, 150, 166, 210]);
      tree.remove(166);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.remove(150);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting - 2);
      expect(depthAfterInserting, depthBeforeInserting - 1);

      expect(tree.freeNodesIds, containsAll(["2", "3"]));
    });

    test('remove with only two nodes - fusion with right sibling', () {
      var tree = BSharpTree<num>(3);
      TreeLoggerObserver(tree);
      tree.insertAll([10, 22, 150, 166, 210]);
      tree.remove(166);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.remove(10);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting - 2);
      expect(depthAfterInserting, depthBeforeInserting - 1);

      expect(tree.freeNodesIds, containsAll(["2", "3"]));
    });

    test('remove with left and right siblings fusion', () {
      var tree = BSharpTree<num>(3);
      TreeLoggerObserver(tree);
      tree.insertAll([10, 22, 150, 166, 210, 233, 370]);
      tree.remove(233);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;
      tree.remove(150);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting - 1);
      expect(depthAfterInserting, depthBeforeInserting);

      expect(tree.freeNodesIds, contains("4"));
    });

    test('remove with two right siblings fusion', () {
      var tree = BSharpTree<num>(3);
      TreeLoggerObserver(tree);
      tree.insertAll([10, 22, 150, 166, 210, 233, 370]);
      tree.remove(233);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;
      tree.remove(10);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting - 1);
      expect(depthAfterInserting, depthBeforeInserting);

      expect(tree.freeNodesIds, contains("4"));
    });

    test('remove with two left sibling fusion', () {
      var tree = BSharpTree<num>(3);
      TreeLoggerObserver(tree);
      tree.insertAll([10, 22, 150, 166, 210, 233, 370]);
      tree.remove(233);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.remove(210);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting - 1);
      expect(depthAfterInserting, depthBeforeInserting);

      expect(tree.freeNodesIds, contains("3"));
    });

    test('remove with right sibling balancing on index node', () {
      var tree = BSharpTree<num>(2);
      TreeLoggerObserver(tree);
      tree.insertAll([10, 22, 150, 166, 210, 233, 370]);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.remove(22);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting - 1);
      expect(depthAfterInserting, depthBeforeInserting);

      expect(tree.freeNodesIds, contains("4"));
    });

    test('remove with left sibling balancing on index node', () {
      var tree = BSharpTree<num>(2);
      TreeLoggerObserver(tree);
      tree.insertAll([22, 36, 150, 166, 210, 121, 75, 17, 45]);
      tree.remove(166);
      tree.remove(121);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;

      tree.remove(210);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting - 1);
      expect(depthAfterInserting, depthBeforeInserting);

      expect(tree.freeNodesIds, contains("3"));
    });

    test('remove with index node fusion with right sibling', () {
      var tree = BSharpTree<num>(2);
      TreeLoggerObserver(tree);
      tree.insertAll([22, 36, 150, 166, 210, 121, 75]);
      tree.remove(150);
      tree.remove(121);
      tree.remove(75);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;
      tree.remove(22);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting - 3);
      expect(depthAfterInserting, depthBeforeInserting - 1);

      expect(tree.freeNodesIds, containsAll(["5", "6", "7"]));
    });

    test('remove with index node fusion with left sibling', () {
      var tree = BSharpTree<num>(2);
      TreeLoggerObserver(tree);
      tree.insertAll([22, 36, 150, 166, 210, 121, 75]);
      tree.remove(150);
      tree.remove(121);
      tree.remove(75);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;
      tree.remove(210);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting - 3);
      expect(depthAfterInserting, depthBeforeInserting - 1);

      expect(tree.freeNodesIds, containsAll(["3", "6", "7"]));
    });

    test('remove with two right siblings balancing', () {
      var tree = BSharpTree<num>(3);
      TreeLoggerObserver(tree);
      tree.insertAll([10, 22, 150, 166, 210, 233, 370]);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;
      tree.remove(22);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting);
      expect(depthAfterInserting, depthBeforeInserting);

      expect(tree.freeNodesIds, isEmpty);
    });

    test('remove with two left siblings balancing', () {
      var tree = BSharpTree<num>(3);
      TreeLoggerObserver(tree);
      tree.insertAll([10, 22, 150, 166, 210, 75, 102, 56]);
      tree.remove(166);

      int nodeQuantityBeforeInserting = tree.nodesQuantity;
      int depthBeforeInserting = tree.depth;
      tree.remove(150);

      int nodeQuantityAfterInserting = tree.nodesQuantity;
      int depthAfterInserting = tree.depth;

      expect(nodeQuantityAfterInserting, nodeQuantityBeforeInserting);
      expect(depthAfterInserting, depthBeforeInserting);

      expect(tree.freeNodesIds, isEmpty);
    });
  });

  group("Obtain all nodes in a map", () {
    test('one level tree', () {
      var tree = BSharpTree<num>(3);
      TreeLoggerObserver(tree);
      tree.insertAll([10, 22, 150, 90]);
      var allNodesByLevel = tree.getAllNodesByLevel();

      expect(allNodesByLevel.length, 1);
      expect(allNodesByLevel[0]!.length, 1);
    });

    test('two level tree', () {
      var tree = BSharpTree<num>(3);
      TreeLoggerObserver(tree);
      tree.insertAll([10, 22, 150, 90, 76]);

      var allNodesByLevel = tree.getAllNodesByLevel();

      expect(allNodesByLevel.length, 2);
      expect(allNodesByLevel[0]!.length, 2);
      expect(allNodesByLevel[1]!.length, 1);
    });

    test('three level tree', () {
      var tree = BSharpTree<num>(3);
      TreeLoggerObserver(tree);
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

  group("Insert and remove values - ", () {
    test("reuse of node id after release it", () {
      var tree = BSharpTree<num>(2);
      TreeLoggerObserver(tree);
      tree.insertAll([22, 36, 150, 166, 210, 121, 75, 17, 45]);
      tree.remove(166);
      tree.remove(121);
      tree.remove(210);

      var freeNodeIdsBeforeInsert = List.of(tree.freeNodesIds);
      var nodeQuantityBeforeInserting = tree.nodesQuantity;

      tree.insert(44);
      tree.insert(5);

      expect(freeNodeIdsBeforeInsert, hasLength(1));
      expect(tree.freeNodesIds, isEmpty);
      expect(tree.nodesQuantity, nodeQuantityBeforeInserting + 1);
    });

    test("new node if there's no free nodes", () {
      var tree = BSharpTree<num>(2);
      tree.insertAll([22, 36, 150, 166, 210, 121, 75, 17, 45]);
      tree.remove(166);
      tree.remove(121);
      tree.remove(210);

      var lastNodeIdBeforeInsert = tree.lastNodeId;

      tree.insert(44);
      tree.insert(5);

      expect(tree.freeNodesIds, isEmpty);
      tree.insert(39);

      expect(tree.lastNodeId, lastNodeIdBeforeInsert + 1);
    });
  });

  group("find tests", () {
    test("find a value that's in the tree", () {
      var tree = BSharpTree<num>(2);
      tree.insertAll([10, 22, 150, 166, 210, 233, 370]);

      var nodeId = tree.find(166);

      expect(nodeId, "8");
    });

    test("find a value that's not in the tree", () {
      var tree = BSharpTree<num>(2);
      tree.insertAll([10, 22, 150, 166, 210, 233, 370]);

      var nodeId = tree.find(23);

      expect(nodeId, "4");
    });
  });
}
