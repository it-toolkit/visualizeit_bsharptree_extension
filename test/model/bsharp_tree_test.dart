import 'package:flutter_test/flutter_test.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_tree.dart';

void main(){
  test('Root Division',(){
    var tree = BSharpTree<num>(3);
    tree.insert(5);
    tree.insert(9);
    tree.insert(7);
    tree.insert(1);
    tree.traverse();
  });

  test('Right Node Balancing',(){
    var tree = BSharpTree<num>(3);
    tree.insert(5);
    tree.insert(9);
    tree.insert(7);
    tree.insert(1);
    tree.traverse();
    tree.insert(4);
    tree.insert(3);
    tree.traverse();
  });

  test('Left Node Balancing',(){
    var tree = BSharpTree<num>(3);
    tree.insert(5);
    tree.insert(9);
    tree.insert(7);
    tree.insert(1);
    tree.traverse();
    tree.insert(8);
    tree.insert(10);
    tree.traverse();
  });
}