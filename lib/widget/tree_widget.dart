import 'package:flutter/material.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_tree.dart';
import 'package:visualizeit_bsharptree_extension/widget/tree_node_widget.dart';
import 'package:widget_arrows/widget_arrows.dart';

class TreeWidget extends StatefulWidget {
  BSharpTree tree;

  TreeWidget(this.tree, {super.key});

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
    _components = createWidgetsFromTree(widget.tree);
  }

  Map<int, List<Widget>> createWidgetsFromTree(BSharpTree tree) {
    return tree.getAllNodesByLevel().map((level, listOfNodes) => MapEntry(
        level, listOfNodes.map((node) => TreeNodeWidget(node)).toList()));
  }

  modifyTree(String text) {
    //Este metodo deberia pasarselo al tree container para agregarlo al
    print("se ingreso este valor $text");
    setState(() {
      widget.tree.insert(int.parse(text));
      _components = createWidgetsFromTree(widget.tree);
    });
  }

  @override
  Widget build(BuildContext context) {
    final myController = TextEditingController();

    final List<Widget> rows = [const Spacer()];

    for (var mapEntry in _components!.entries) {
      List<Widget> children = mapEntry.value.fold([
        const Spacer()
      ], (previousValue, widget) => previousValue + ([widget, const Spacer()]));
      rows.addAll([Row(children: children), const Spacer()]);
    }

    rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 80,
            child: TextField(
                maxLength: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'valor a insertar',
                ),
                controller: myController),
          ),
          ElevatedButton(
              onPressed: () {
                modifyTree(myController.text);
                myController.clear();
              },
              child: const Text("insertar"))
        ]));

    return ArrowContainer(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: rows),
    );
  }
}
