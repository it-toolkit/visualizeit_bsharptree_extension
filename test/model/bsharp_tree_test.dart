import 'package:flutter_test/flutter_test.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_tree.dart';

void main(){
  test('Root Splitting',(){
    var tree = BSharpTree<num>(3);
    tree.insert(150);
    tree.insert(209);
    tree.insert(113);
    tree.insert(322);
    tree.insert(95);
    //tree.insert(278);
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

  test('index node balancing',(){
    var tree = BSharpTree<num>(3);
    tree.insert(5);
    tree.insert(9);
    tree.insert(7);
    tree.insert(1);
    tree.printTree();
    //tree.traverse();
    tree.insert(4);
    tree.insert(3);
    tree.printTree();
    tree.insert(2);
    tree.printTree();
    //tree.traverse();
    tree.insert(10);
    tree.printTree();
    tree.insert(6);
    tree.printTree();
    //tree.traverse();
  });
}