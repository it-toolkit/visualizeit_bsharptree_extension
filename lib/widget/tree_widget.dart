import 'package:flutter/material.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_transition.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_node.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_tree.dart';
import 'package:visualizeit_bsharptree_extension/widget/tree_node_widget.dart';
import 'package:widget_arrows/widget_arrows.dart';

class TreeWidget extends StatefulWidget {
  final BSharpTree tree;
  final BSharpTreeTransition? currentTransition;

  const TreeWidget(this.tree, this.currentTransition, {super.key});

  @override
  State<TreeWidget> createState() {
    return _TreeWidgetState();
  }
}

class _TreeWidgetState extends State<TreeWidget> {
  Map<int, List<Widget>>? _components;

  _TreeWidgetState();

  @override
  void initState() {
    super.initState();
    _components = createWidgetsFromTree();
  }

  Map<int, List<Widget>> createWidgetsFromTree() {
    return widget.tree.getAllNodesByLevel().map((level, listOfNodes) =>
        MapEntry(
            level,
            listOfNodes
                .map((node) => createNodeWithTransition(node))
                .toList()));
  }

  TreeNodeWidget createNodeWithTransition(BSharpNode<Comparable> node) {
    var isRead = widget.currentTransition != null
        ? widget.currentTransition is NodeRead &&
            widget.currentTransition!.targetId == node.id
        : false;
    var isWritten = widget.currentTransition != null
        ? widget.currentTransition is NodeWritten &&
            widget.currentTransition!.targetId == node.id
        : false;
    return TreeNodeWidget(node, isRead, isWritten);
  }

  @override
  Widget build(BuildContext context) {
    _components = createWidgetsFromTree();

    final List<Widget> rows = [
      const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 80,
            child: Text("Nodos libres:"),
          )
        ],
      )
    ];

    for (var mapEntry in _components!.entries) {
      List<Widget> children = mapEntry.value.fold([
        const Spacer()
      ], (previousValue, widget) => previousValue + ([widget, const Spacer()]));
      rows.addAll([Row(children: children), const Spacer()]);
    }

    return ArrowContainer(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: rows),
    );
  }
}
