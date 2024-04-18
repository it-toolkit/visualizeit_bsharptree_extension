import 'dart:math';

import 'package:flutter/material.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_tree.dart';
import 'package:visualizeit_bsharptree_extension/widget/tree_component.dart';
import 'package:visualizeit_bsharptree_extension/widget/tree_node_widget.dart';

void main() {
  var tree = BSharpTree<num>(3);
  tree.insert(150);
  tree.insert(209);
  tree.insert(113);
  tree.insert(30025);
  tree.insert(95);
  tree.insert(500);
  tree.insert(12);
  tree.insert(75);
  tree.insert(322);
  tree.insert(812);
  tree.insert(722);
  /*var tree = BSharpTree<num>(2);
  Random random = Random();
  Set<int> setOfInts = {};
  while (setOfInts.length<45){
    setOfInts.add(random.nextInt(1000));
  }
  
  tree.insertAll(setOfInts.toList());
  tree.printTree();*/

  runApp(MyApp(tree));
}

class MyApp extends StatelessWidget {
  final BSharpTree tree;

  const MyApp(this.tree, {super.key});

  @override
  Widget build(BuildContext context) {
    var treeNodes = tree.getAllNodesByLevel();
    var map = treeNodes.map((level, listOfNodes) => MapEntry(
        level, listOfNodes.map((node) => TreeNodeWidget(node)).toList()));

    return MaterialApp(
        title: 'Visualize IT',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: Scaffold(
            body: InteractiveViewer(
                clipBehavior: Clip.none,
                child: TreeContainer(
                  components: map,
                ))));
  }
}
