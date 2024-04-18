import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:visualizeit_bsharptree_extension/exception/element_insertion_exception.dart';
import 'package:visualizeit_bsharptree_extension/exception/element_not_found_exception.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_tree.dart';

void main(){

  group("Insert value tests", () { 
    test('Root Splitting',(){
      var tree = BSharpTree<num>(3);
      tree.insert(150);
      tree.insert(209);
      tree.insert(113);
      tree.insert(322);
      tree.insert(95);
      tree.printTree();
    });

    test('Left Node Balancing',(){
      var tree = BSharpTree<num>(3);
      tree.insert(150);
      tree.insert(209);
      tree.insert(113);
      tree.insert(322);
      tree.insert(95);
      tree.printTree();
      tree.insert(278);
      tree.printTree();
    });

    test('Right Node Balancing',(){
      var tree = BSharpTree<num>(3);
      tree.insert(150);
      tree.insert(209);
      tree.insert(113);
      tree.insert(322);
      tree.insert(95);
      tree.insert(78);
      tree.insert(23);
      tree.insert(9);
      tree.printTree();
      tree.insert(55);
      tree.printTree();
    });

    test('full leaf nodes splitting (fusion with right sibling)',(){
      var tree = BSharpTree<num>(3);
      tree.insert(150);
      tree.insert(209);
      tree.insert(113);
      tree.insert(322);
      tree.insert(95);
      tree.insert(278);
      tree.printTree();
      tree.insert(12);
      tree.printTree();
    });

    test('full leaf nodes splitting (fusion with left sibling)',(){
      var tree = BSharpTree<num>(3);
      tree.insert(150);
      tree.insert(209);
      tree.insert(113);
      tree.insert(322);
      tree.insert(95);
      tree.insert(278);
      tree.printTree();
      tree.insert(305);
      tree.printTree();
    });

    test('index node splitting',(){
      var tree = BSharpTree<num>(3);
      tree.insert(150);
      tree.insert(209);
      tree.insert(113);
      tree.insert(322);
      tree.insert(95);
      tree.insert(278);
      tree.insert(15);
      tree.insert(74);
      tree.insert(188);
      tree.insert(525);
      tree.insert(106);
      tree.insert(137);
      tree.insert(225);
      tree.printTree();
      tree.insert(7);
      tree.printTree();
    });

    test('index node balancing, with rotation with right sibling',(){
      var tree = BSharpTree<num>(3);
      tree.insert(150);
      tree.insert(209);
      tree.insert(113);
      tree.insert(322);
      tree.insert(95);
      tree.insert(278);
      tree.insert(15);
      tree.insert(74);
      tree.insert(188);
      tree.insert(525);
      tree.insert(106);
      tree.insert(137);
      tree.insert(225);
      tree.insert(7);
      tree.insert(33);
      tree.insert(99);
      tree.insert(10);
      tree.printTree();
      tree.insert(121);
      tree.printTree();
    });

    test('index node balancing, with rotation with left sibling',(){
      var tree = BSharpTree<num>(3);
      tree.insert(150);
      tree.insert(209);
      tree.insert(113);
      tree.insert(322);
      tree.insert(95);
      tree.insert(278);
      tree.insert(15);
      tree.insert(74);
      tree.insert(188);
      tree.insert(525);
      tree.insert(106);
      tree.insert(137);
      tree.insert(225);
      tree.insert(7);
      tree.insert(166);
      tree.insert(264);
      tree.insert(192);
      tree.printTree();
      tree.insert(722);
      tree.printTree();
    });

    test('full index nodes splitting (fusion with right sibling)',(){
      var tree = BSharpTree<num>(3);
      tree.insert(150);
      tree.insert(209);
      tree.insert(113);
      tree.insert(322);
      tree.insert(95);
      tree.insert(278);
      tree.insert(15);
      tree.insert(74);
      tree.insert(188);
      tree.insert(525);
      tree.insert(106);
      tree.insert(137);
      tree.insert(225);
      tree.insert(7);
      tree.insert(33);
      tree.insert(99);
      tree.insert(10);
      tree.printTree();
      tree.insert(121);
      tree.insert(2);
      tree.insert(21);
      tree.printTree();
      tree.insert(12);
      tree.printTree();
    });

    test('full index nodes splitting (fusion with left sibling)',(){
      var tree = BSharpTree<num>(2);
      tree.insert(150);
      tree.insert(209);
      tree.insert(113);
      tree.insert(322);
      tree.insert(95);
      tree.insert(278);
      tree.insert(15);
      tree.insert(525);
      tree.insert(674);
      tree.printTree();
      tree.insert(589);
      tree.printTree();
    });

    test('4th level - random numbers',(){
      var tree = BSharpTree<num>(2);
      Random random = Random();
      Set<int> setOfInts = {};
      while (setOfInts.length<25){
        setOfInts.add(random.nextInt(1000));
      }
      
      tree.insertAll(setOfInts.toList());
      tree.printTree();
    });

    test('5th level - random numbers ',(){
      var tree = BSharpTree<num>(2);
      Random random = Random();
      Set<int> setOfInts = {};
      while (setOfInts.length<45){
        setOfInts.add(random.nextInt(1000));
      }
      
      tree.insertAll(setOfInts.toList());
      expect(tree.depth, 4);
      tree.printTree();
      
      List<int> shuffledList = setOfInts.toList();
      shuffledList.shuffle();
      
      for (var value in shuffledList) {
        tree.remove(value);
      }

      expect(tree.depth, 0);
      tree.printTree();
    });

    test('same number insertion',(){
      var tree = BSharpTree<num>(2);
      tree.insert(150);
      tree.insert(209);
      tree.insert(113);
      tree.insert(322);
      tree.insert(95);
      expect(() =>tree.insert(150), throwsA(const TypeMatcher<ElementInsertionException>()));
    });

    test('depth 0 when the tree is empty',(){
      var tree = BSharpTree<num>(2);
      expect(tree.depth, 0);
    });

  });

  group("remove value tests - ", () { 

    test('element not found',(){
      var tree = BSharpTree<num>(3);
      tree.insert(10);
      tree.insert(22);
      tree.insert(150);
      tree.insert(166);
      tree.printTree();

      expect(() =>tree.remove(7), throwsA(const TypeMatcher<ElementNotFoundException>()));     
    });

    test('remove with right sibling balancing',(){
      var tree = BSharpTree<num>(3);
      tree.insert(10);
      tree.insert(22);
      tree.insert(150);
      tree.insert(166);
      tree.insert(210);
      tree.insert(233);
      tree.insert(370);
      tree.insert(421);
      tree.printTree();
      tree.remove(22);
      tree.printTree();
    });

    test('remove with left sibling balancing',(){
      var tree = BSharpTree<num>(3);
      tree.insert(10);
      tree.insert(22);
      tree.insert(150);
      tree.insert(166);
      tree.insert(233);
      tree.insert(370);
      tree.remove(233);
      tree.printTree();
      tree.remove(166);
      tree.printTree();
    });

    test('remove with right sibling fusion',(){
      var tree = BSharpTree<num>(3);
      tree.insert(10);
      tree.insert(22);
      tree.insert(150);
      tree.insert(166);
      tree.insert(210);
      tree.insert(233);
      tree.insert(370);
      tree.remove(233);
      tree.printTree();
      tree.remove(150);
      tree.printTree();
    });

    test('remove with left sibling fusion',(){
      var tree = BSharpTree<num>(3);
      tree.insert(10);
      tree.insert(22);
      tree.insert(150);
      tree.insert(166);
      tree.insert(210);
      tree.insert(233);
      tree.insert(370);
      tree.remove(233);
      tree.printTree();
      tree.remove(210);
      tree.printTree();
    });

    test('remove with right sibling balancing on index node',(){
      var tree = BSharpTree<num>(2);
      tree.insert(10);
      tree.insert(22);
      tree.insert(150);
      tree.insert(166);
      tree.insert(210);
      tree.insert(233);
      tree.insert(370);
      tree.printTree();
      tree.remove(22);
      tree.printTree();
    });

    test('remove with left sibling balancing on index node',(){
      var tree = BSharpTree<num>(2);
      tree.insert(22);
      tree.insert(36);
      tree.insert(150);
      tree.insert(166);
      tree.insert(210);
      tree.insert(121);
      tree.insert(75);
      tree.insert(17);
      tree.insert(45);
      tree.remove(166);
      tree.remove(121);
      tree.printTree();
      tree.remove(210);
      tree.printTree();
    });

    test('remove with index node fusion with right sibling',(){
      var tree = BSharpTree<num>(2);
      tree.insert(22);
      tree.insert(36);
      tree.insert(150);
      tree.insert(166);
      tree.insert(210);
      tree.insert(121);
      tree.insert(75);
      tree.remove(150);
      tree.remove(121);
      tree.remove(75);
      tree.printTree();
      tree.remove(22);
      tree.printTree();
    });

    test('remove with index node fusion with left sibling',(){
      var tree = BSharpTree<num>(2);
      tree.insert(22);
      tree.insert(36);
      tree.insert(150);
      tree.insert(166);
      tree.insert(210);
      tree.insert(121);
      tree.insert(75);
      tree.remove(150);
      tree.remove(121);
      tree.remove(75);
      tree.printTree();
      tree.remove(210);
      tree.printTree();
    });

    test('remove with two right siblings balancing',(){
      var tree = BSharpTree<num>(3);
      tree.insert(10);
      tree.insert(22);
      tree.insert(150);
      tree.insert(166);
      tree.insert(210);
      tree.insert(233);
      tree.insert(370);
      tree.printTree();
      tree.remove(22);
      tree.printTree();
    });

    test('remove with two left siblings balancing',(){
      var tree = BSharpTree<num>(3);
      tree.insert(10);
      tree.insert(22);
      tree.insert(150);
      tree.insert(166);
      tree.insert(210);
      tree.insert(75);
      tree.insert(102);
      tree.insert(56);
      tree.remove(166);
      tree.printTree();
      tree.remove(150);
      tree.printTree();
    });

  });

  group("Obtain all nodes in a map", () {
    test('one level tree',(){
      var tree = BSharpTree<num>(3);
      tree.insert(10);
      tree.insert(22);
      tree.insert(150);
      tree.insert(90);
      var allNodesByLevel = tree.getAllNodesByLevel();
      
      expect(allNodesByLevel.length, 1);
      expect(allNodesByLevel[0]!.length, 1);
    });

    test('two level tree',(){
      var tree = BSharpTree<num>(3);
      tree.insert(10);
      tree.insert(22);
      tree.insert(150);
      tree.insert(90);
      tree.insert(76);
      tree.printTree();
      var allNodesByLevel = tree.getAllNodesByLevel();
      
      expect(allNodesByLevel.length, 2);
      expect(allNodesByLevel[0]!.length, 2);
      expect(allNodesByLevel[1]!.length, 1);
    });

    test('three level tree',(){
      var tree = BSharpTree<num>(3);
      tree.insert(150);
      tree.insert(209);
      tree.insert(113);
      tree.insert(322);
      tree.insert(95);
      tree.insert(278);
      tree.insert(15);
      tree.insert(74);
      tree.insert(188);
      tree.insert(525);
      tree.insert(106);
      tree.insert(137);
      tree.insert(225);
      tree.insert(7);
      tree.insert(166);
      tree.insert(264);
      tree.insert(192);
      tree.insert(722);
      tree.printTree();

      var allNodesByLevel = tree.getAllNodesByLevel();
      
      expect(allNodesByLevel.length, 3);
      expect(allNodesByLevel[0]!.length, 8);
      expect(allNodesByLevel[1]!.length, 2);
      expect(allNodesByLevel[2]!.length, 1);
    });
  });
  
}