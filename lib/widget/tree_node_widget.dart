import 'dart:math';

import 'package:flutter/material.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_transition.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_index_node.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_node.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_sequential_node.dart';
import 'package:visualizeit_bsharptree_extension/widget/component.dart';
import 'package:widget_arrows/widget_arrows.dart';

class TreeNodeWidget extends StatelessWidget {
  final BSharpNode node;
  final BSharpTreeTransition? transition;
  final double scaleFactor;

  const TreeNodeWidget(this.node, this.transition,
      {this.scaleFactor = 1.0, super.key});

  List<Component> buildComponents() {
    final valueNodes = <Widget>[];
    String nodeId = node.id;
    var colorByCapacityState = getColorByCapacityState(node);
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
          _boxContainer(firstValue.key.toString(), colorByCapacityState)
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
      } else {
        valueNodes.add(_boxContainer(" ", colorByCapacityState).link(
            "${nodeId}_${indexNode.leftNode.id}",
            Alignment.bottomLeft,
            indexNode.leftNode.id,
            Alignment.topCenter,
            straight: true));
        valueNodes.add(const Spacer());
      }

      for (var indexRecord in nextValues) {
        String key = indexRecord.key.toString();
        valueNodes.addAll([
          _boxContainer(key, colorByCapacityState).link(
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
          _boxContainer(value.toString(), colorByCapacityState),
          _boxContainer("...", colorByCapacityState, width: 15, padding: 0.0)
        ]);
      }
      valueNodes.add(const Spacer());
    }

    return <Component>[
      Component(
        "node-$nodeId",
        Alignment.topCenter,
        SizedBox(
          width: 30 * scaleFactor,
          height: 20 * scaleFactor,
          child: FittedBox(
              fit: BoxFit.fitHeight,
              alignment: Alignment.bottomCenter,
              child: Text(nodeId,
                  style: const TextStyle(
                      color: Colors.black, decoration: TextDecoration.none))),
        ),
      ),
      Component(
        "values-$nodeId",
        const Alignment(0, 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: valueNodes,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final List<Component> components = buildComponents();

    var boxBorderWidth = transition != null ? 2.0 : 1.0;
    var boxBorderColor = transition != null
        ? transition!.getBoxBorderColorForWidget()
        : Colors.black;
    var scaledBorderRadius = 10 * scaleFactor;
    Widget nodeBox = Container(
        width: max(80, 30 + node.length() * 50) * scaleFactor,
        height: 65 * scaleFactor,
        decoration: BoxDecoration(
            border: Border.all(
                width: boxBorderWidth * scaleFactor,
                color: boxBorderColor,
                strokeAlign: BorderSide.strokeAlignOutside),
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(scaledBorderRadius)),
            boxShadow: const [
              BoxShadow(blurRadius: 5),
            ]),
        child: Column(
          children: buildComponentsContainers(components),
        ));
    if (node is BSharpSequentialNode) {
      var sequentialNode = node as BSharpSequentialNode;
      if (sequentialNode.nextNode != null) {
        nodeBox = nodeBox.link(
            "${sequentialNode.id}-${sequentialNode.nextNode!.id}",
            Alignment.centerRight,
            sequentialNode.nextNode!.id,
            Alignment.centerLeft,
            straight: true);
      }
    }
    return ArrowElement(id: node.id, child: nodeBox);
  }

  List<Widget> buildComponentsContainers(List<Component> components) {
    var widgets = <Widget>[];
    if (transition != null) {
      String text = transition!.getTextForWidget();
      Color textColor = transition!.getTextColorForWidget();
      widgets.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Container(
            child: components[0].widget,
          ),
          Container(
            alignment: Alignment.bottomRight,
            padding: const EdgeInsets.fromLTRB(0.0, 1.0, 3.5, 1.0),
            child: SizedBox(
              width: (30.0 + text.length.toDouble() * 1.5) * scaleFactor,
              height: 18 * scaleFactor,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomRight,
                child: Text(
                  text,
                  style: TextStyle(
                      color: textColor, backgroundColor: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ));
    } else {
      widgets.add(
          Container(alignment: Alignment.topLeft, child: components[0].widget));
    }
    widgets.add(Container(
        alignment: Alignment.bottomCenter, child: components[1].widget));
    return widgets;
  }

  Widget _boxContainer(String text, Color color,
      {double margin = 0.0,
      double width = 35.0,
      double height = 40.0,
      double padding = 5.0}) {
    return Container(
      width: width * scaleFactor,
      height: height * scaleFactor,
      margin: EdgeInsets.all(margin * scaleFactor),
      padding: EdgeInsets.all(padding * scaleFactor),
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

  Color getColorByCapacityState(BSharpNode node) {
    if (node.isOverflowed()) {
      return Colors.red;
    } else if (node.isAtMaxCapacity()) {
      return Colors.yellow;
    } else {
      return Colors.cyan;
    }
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
