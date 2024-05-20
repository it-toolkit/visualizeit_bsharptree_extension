import 'dart:math';

import 'package:flutter/material.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_transition.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_tree.dart';
import 'package:visualizeit_bsharptree_extension/widget/tree_widget.dart';

void main() {
  BSharpTree<num> tree = BSharpTree<num>(3);
  Random random = Random();
  Set<int> setOfInts = {};
  while (setOfInts.length < 80) {
    setOfInts.add(random.nextInt(1000));
  }

  tree.insertAll(setOfInts.toList());

  runApp(MyApp(tree));
}

class MyApp extends StatelessWidget {
  final BSharpTree tree;

  const MyApp(this.tree, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Visualize IT',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: InteractiveViewer(
          clipBehavior: Clip.none,
          child: TreeWidget(tree, NodeRead(targetId: "2")),
        ),
      ),
    );
  }
}
