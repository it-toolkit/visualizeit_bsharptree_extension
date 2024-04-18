import 'package:flutter/material.dart';
import 'package:widget_arrows/widget_arrows.dart';

class TreeContainer extends StatelessWidget {
  final myController = TextEditingController();

  final Map<int, List<Widget>> _components;

  TreeContainer({super.key, required Map<int, List<Widget>> components}) : _components = components;

  @override
  Widget build(BuildContext context) {

    final List<Widget> rows = [const Spacer()];

    for (var mapEntry in _components.entries) {
      List<Widget> children = mapEntry.value.fold([const Spacer()], (previousValue, widget) => previousValue + ([widget, const Spacer()]));
      rows.addAll([Row(children: children,), const Spacer(), ]);
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
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                // Retrieve the text the that user has entered by using the
                // TextEditingController.
                content: Text(myController.text),
              );
            },
          );
          myController.clear();
        },
        child: const Text("insertar")));
    return ArrowContainer(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: rows,));
  }

}
