import 'dart:math';

import 'package:flutter/material.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_index_node.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_node.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_sequential_node.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_tree.dart';
import 'package:visualizeit_bsharptree_extension/widget/animation/bsharp_index_node_widget.dart';
import 'package:visualizeit_bsharptree_extension/widget/animation/bsharp_sequential_node_widget.dart';
import 'package:widget_arrows/widget_arrows.dart';

class NewTreeWidget extends StatefulWidget {
  final BSharpTree tree;
  const NewTreeWidget(this.tree, {super.key});

  @override
  State<NewTreeWidget> createState() => _NewTreeWidgetState();
}

class _NewTreeWidgetState extends State<NewTreeWidget> {
  @override
  Widget build(BuildContext context) {
    return ArrowContainer(
        child:
            AnimatedBuilder(animation: widget.tree, builder: buildComponents2));
  }

  Widget buildComponents2(BuildContext context, Widget? child) {
    List<Widget> rows = [const Spacer()];
    rows.add(const Spacer());
    rows.addAll(createRowsFromTree());
    rows.add(Row(
      children: [
        ElevatedButton(
          onPressed: modifyTree,
          child: const Text('insert'),
        )
      ],
    ));
    rows.add(const Spacer());
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }

  Widget buildComponents(BuildContext context, Widget? child) {
    List<BSharpNode> nodes =
        widget.tree.getAllNodesByLevel().values.elementAt(0);
    List<String> nodeValues = nodes.isNotEmpty
        ? (nodes.elementAt(0) as BSharpSequentialNode)
            .values
            .map((e) => e.toString())
            .toList()
        : [];
    return Row(
      children: <Widget>[
        for (final String value in nodeValues)
          Container(child: _boxContainer(value))
      ],
    );
  }

  static Widget _boxContainer(String text,
      {double margin = 0.0, Color color = Colors.cyan}) {
    return Container(
      width: 35.0,
      height: 40.0,
      margin: EdgeInsets.all(margin),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(),
        color: color,
      ),
      alignment: Alignment.center,
      child: FittedBox(
          fit: BoxFit.fitWidth,
          child: Text(text,
              style: const TextStyle(
                decoration: TextDecoration.none,
              ))),
    );
  }

  void modifyTree() {
    widget.tree.insert(Random().nextInt(1000));
  }

  List<Widget> createRowsFromTree() {
    List<Widget> rows = [];
    var mapNodesByLevel =
        widget.tree.getAllNodesByLevel().map(buildTreeNodeWidgetsByRow);
    List<Row> rowOfNodes =
        mapNodesByLevel.values.map((nodes) => Row(children: nodes)).toList();
    rows.addAll(rowOfNodes);
    /*Map<int, List<Widget>> treeNodesByRow = widget.tree
        .getAllNodesByLevel()
        .map((level, listOfNodes) => MapEntry(
            level,
            listOfNodes
                .map((node) => BSharpSequentialNodeWidget(node))
                .toList()));
    for (var treeNodes in treeNodesByRow.entries) {
      rows.add(Row(
        children: treeNodes.value,
      ));
    }*/
    return rows;
  }

  MapEntry<int, List<Widget>> buildTreeNodeWidgetsByRow(
      int level, List<BSharpNode> listOfNodes) {
    if (level == 0) {
      return MapEntry(
          level,
          listOfNodes
              .map((e) => BSharpSequentialNodeWidget(e as BSharpSequentialNode))
              .toList());
    } else {
      return MapEntry(
          level,
          listOfNodes
              .map((e) => BSharpIndexNodeWidget(e as BSharpIndexNode))
              .toList());
    }
  }
}
