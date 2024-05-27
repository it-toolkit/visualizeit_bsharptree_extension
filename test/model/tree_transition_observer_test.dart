import 'package:flutter_test/flutter_test.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_transition.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_tree.dart';
import 'package:visualizeit_bsharptree_extension/model/tree_transition_observer.dart';

void main() {
  group("tree transitions observed", () {
    test("insertion with splitting, balancing and creation of new nodes", () {
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
      var treeTransitionObserver = TreeTransitionObserver(tree);

      tree.insert(722);

      var transitions = treeTransitionObserver.transitions;
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

    test("removal with fusion and release of nodes", () {
      var tree = BSharpTree<num>(3);
      tree.insertAll([10, 22, 150, 166, 210, 233, 370]);
      tree.remove(233);

      var treeTransitionObserver = TreeTransitionObserver(tree);
      tree.remove(10);

      var transitions = treeTransitionObserver.transitions;
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

    test("removal with balancing", () {
      var tree = BSharpTree<num>(3);
      tree.insertAll([10, 22, 150, 166, 210, 233, 370]);
      var treeTransitionObserver = TreeTransitionObserver(tree);
      tree.remove(22);

      var transitions = treeTransitionObserver.transitions;
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

    test("find function observed", () {
      var tree = BSharpTree<num>(2);
      tree.insertAll([10, 22, 150, 166, 210, 233, 370]);

      var transitionObserver = TreeTransitionObserver(tree);

      var transitions = transitionObserver.transitions;

      expect(transitions, hasLength(0));

      tree.find(166);

      expect(transitions, hasLength(4));
      expect(transitions[0], predicate<NodeRead>((t) => t.targetId == "0-1"));
      expect(transitions[1], predicate<NodeRead>((t) => t.targetId == "7"));
      expect(transitions[2], predicate<NodeRead>((t) => t.targetId == "8"));
      expect(transitions[3], predicate<NodeFound>((t) => t.targetId == "8"));
    });
  });
}
