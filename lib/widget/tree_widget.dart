import 'package:flutter/material.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_tree.dart';
import 'package:visualizeit_bsharptree_extension/widget/tree_node_widget.dart';
import 'package:widget_arrows/widget_arrows.dart';

class TreeWidget extends StatefulWidget {
  BSharpTree<num> tree;

  TreeWidget(this.tree, {super.key});

  @override
  State<TreeWidget> createState() {
    return _TreeWidgetState(tree);
  }
}

class _TreeWidgetState extends State<TreeWidget> {
  BSharpTree<num> tree;

  Map<int, List<Widget>>? _components;

  _TreeWidgetState(this.tree);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  modifyTree(String text) {
    //Este metodo deberia pasarselo al tree container para agregarlo al
    print("se ingreso este valor $text");
    setState(() {
      tree.insert(int.parse(text));
      var treeNodes = tree.getAllNodesByLevel();
      _components = treeNodes.map((level, listOfNodes) => MapEntry(
          level, listOfNodes.map((node) => TreeNodeWidget(node)).toList()));
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
      rows.addAll([
        Row(
          children: children,
        ),
        const Spacer(),
      ]);
    }
    //rows.add(const Row(children: [ Column(children: [TextField(maxLength: 4,)],), Column(), Column()]));

    //rows.add(Container(height: 100, width: 180, child: Row(children: [Container(child:Text("dataasdasd")), Container(child:TextField(maxLength: 4,))],)));
    rows.add(SizedBox(
        height: 50,
        width: 80,
        child: TextField(
          maxLength: 4,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'valor a insertar',
          ),
          controller: myController,
        )));
    //rows.add( TextButton(onPressed: null, child: Text("insertar")));
    rows.add(ElevatedButton(
        onPressed: () {
          modifyTree(myController.text);
          myController.clear();
        },
        child: const Text("insertar")));
    return ArrowContainer(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: rows,
    ));
  }
}
