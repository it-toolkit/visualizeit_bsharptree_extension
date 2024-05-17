import 'dart:math';

import 'package:flutter/material.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_index_node.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_node.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_sequential_node.dart';
import 'package:visualizeit_bsharptree_extension/widget/component.dart';
import 'package:widget_arrows/widget_arrows.dart';

class TreeNodeWidget extends StatelessWidget {
  final BSharpNode node;

  const TreeNodeWidget(this.node, {super.key});

  List<Component> buildComponents() {
    final valueNodes = <Widget>[];
    String nodeId = node.id;
    if (node is BSharpIndexNode) {
      var indexNode = node as BSharpIndexNode;
      final firstValue = indexNode.rightNodes.firstOrNull;
      final List<IndexRecord> nextValues = indexNode.rightNodes.length > 1
          ? indexNode.rightNodes.sublist(1)
          : [];

      // Tiene que apuntar a izquierda y a derecha el primer valor
      valueNodes.add(const Spacer());
      if (firstValue != null) {
        valueNodes.addAll([
          _boxContainer(firstValue.key.toString())
              .link(
                  nodeId + firstValue.key.toString() + indexNode.leftNode.id,
                  Alignment.bottomLeft,
                  indexNode.leftNode.id,
                  Alignment.topCenter,
                  straight: true)
              .link(
                  nodeId + firstValue.key.toString() + firstValue.rightNode.id,
                  Alignment.bottomRight,
                  firstValue.rightNode.id,
                  Alignment.topCenter,
                  straight: true),
        ]);
      }

      for (var indexRecord in nextValues) {
        String key = indexRecord.key.toString();
        valueNodes.addAll([
          _boxContainer(key).link(
              nodeId + key + indexRecord.rightNode.id,
              Alignment.bottomRight,
              indexRecord.rightNode.id,
              Alignment.topCenter,
              straight: true)
        ]);
      }

      if (firstValue != null) {
        valueNodes.add(const Spacer());
      }
    } else {
      var sequentialNode = node as BSharpSequentialNode;
      valueNodes.add(const Spacer());
      for (var value in sequentialNode.values) {
        valueNodes.addAll([
          _boxContainer(value.toString()),
        ]);
      }
      valueNodes.add(const Spacer());
    }

    return <Component>[
      Component(
        "node-$nodeId",
        Alignment.topCenter,
        SizedBox(
          width: 30,
          height: 20,
          child: FittedBox(
              fit: BoxFit.fitWidth,
              alignment: Alignment.bottomCenter,
              child: Text("Id: $nodeId",
                  style: const TextStyle(
                      color: Colors.black, decoration: TextDecoration.none))),
        ),
      ),
      Component(
        "values-$nodeId",
        const Alignment(0, 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: valueNodes,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final List<Component> components = buildComponents();

    return ArrowElement(
        id: node.id,
        child: Container(
            width: max(50, 20 + node.length() * 35),
            height: 65,
            decoration: BoxDecoration(
                border: Border.all(),
                color: Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                boxShadow: const [
                  BoxShadow(blurRadius: 10),
                ]),
            child: Column(
              children: <Widget>[
                // Create all of the colored boxes in the colors map.
                for (final Component component in components)
                  Container(
                    child: component.widget,
                  ),
              ],
            )));
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
}

extension LinkedWidget on Widget {
  Widget link(String id, Alignment sourceAnchor, String targetId,
      Alignment targetAnchor,
      {bool flip = false, bool straight = false}) {
    return ArrowElement(
      id: id,
      sourceAnchor: sourceAnchor,
      targetAnchor: targetAnchor,
      targetId: targetId,
      flip: flip,
      width: 2,
      tipLength: 5,
      bow: straight ? 0 : 0.2,
      stretchMax: straight ? 1 : 420,
      child: this,
    );
  }

  Widget linked(String id) {
    return ArrowElement(
      id: id,
      width: 2,
      tipLength: 5,
      child: this,
    );
  }
}

extension LinkedComponent on Component {
  Component link(
      Alignment sourceAnchor, String targetId, Alignment targetAnchor,
      {bool flip = false, bool straight = false}) {
    return Component(
        id,
        alignment,
        ArrowElement(
          id: id,
          sourceAnchor: sourceAnchor,
          targetAnchor: targetAnchor,
          targetId: targetId,
          flip: flip,
          width: 2,
          tipLength: 5,
          bow: straight ? 0 : 0.2,
          stretchMax: straight ? 1 : 420,
          child: widget,
        ));
  }

  Component linked() {
    return Component(
        id,
        alignment,
        ArrowElement(
          id: id,
          child: widget,
        ));
  }
}

extension WidgetExtensions on Widget {
  Widget mapIf(bool condition, Widget Function(Widget) block) =>
      condition ? block(this) : this;
}
